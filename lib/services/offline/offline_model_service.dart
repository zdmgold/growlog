import '../storage_check.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:path_provider/path_provider.dart';

import 'identify_math.dart';
import 'model_manifest.dart';
import 'preprocess.dart';

enum OfflineModelState {
  unknown,
  notInstalled,
  waitingForWifi,
  downloading,
  installed,
  failed,
}

class _Cancelled implements Exception {
  const _Cancelled();
}

/// Why a download stopped. The screens turn this into text in the app's language.
enum OfflineErrorKind {
  noInternet,
  timeout,
  server,
  incomplete,
  damaged,
  notEnoughSpace,
  generic
}

class _KindException implements Exception {
  final OfflineErrorKind kind;
  const _KindException(this.kind);
}

/// Downloads, verifies and runs the offline plant-identification model.
///
/// The pack is hosted in a public repository so it keeps working after the main
/// repository goes private. Downloads resume after an interruption and every file
/// is checked against its SHA-256 before it is used.
class OfflineModelService extends ChangeNotifier {
  OfflineModelService._();
  static final OfflineModelService instance = OfflineModelService._();

  static const String manifestUrl =
      'https://github.com/zdmgold/growlog-models/releases/download/v1/model_manifest.json';
  static const String _modelFile = 'bioclip2_image_int8.onnx';
  static const String _textFile = 'text_embeddings_fp16.bin';
  static const String _speciesFile = 'species.json';
  static const String _marker = 'installed.json';

  OfflineModelState _state = OfflineModelState.unknown;
  double _progress = 0;
  int _bytesDone = 0;
  int _bytesTotal = 0;
  OfflineErrorKind? _errorKind;
  ModelManifest? _manifest;
  bool _cancelRequested = false;
  Completer<bool>? _wifiWait;
  StreamSubscription<List<ConnectivityResult>>? _wifiSub;
  List<String>? _species;
  Float32List? _text;

  OfflineModelState get state => _state;
  double get progress => _progress;
  int get bytesDone => _bytesDone;
  int get bytesTotal => _bytesTotal;
  OfflineErrorKind? get errorKind => _errorKind;
  bool get isInstalled => _state == OfflineModelState.installed;
  bool get isDownloading => _state == OfflineModelState.downloading;
  bool get isWaitingForWifi => _state == OfflineModelState.waitingForWifi;
  bool get isBusy => isDownloading || isWaitingForWifi;

  void _set(OfflineModelState s) {
    _state = s;
    notifyListeners();
  }

  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/offline_model_v1');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// Checks what is installed. Call once at app start.
  Future<void> load() async {
    try {
      final dir = await _dir();
      final marker = File('${dir.path}/$_marker');
      if (!await marker.exists()) {
        _set(OfflineModelState.notInstalled);
        return;
      }
      final m = ModelManifest.fromJson(
          jsonDecode(await marker.readAsString()) as Map<String, dynamic>);
      for (final f in m.files) {
        final file = File('${dir.path}/${f.name}');
        if (!await file.exists() || await file.length() != f.bytes) {
          _set(OfflineModelState.notInstalled);
          return;
        }
      }
      _manifest = m;
      _set(OfflineModelState.installed);
    } catch (e) {
      debugPrint('OfflineModelService.load error: $e');
      _set(OfflineModelState.notInstalled);
    }
  }

  Future<bool> _onWifi() async {
    final r = await Connectivity().checkConnectivity();
    return r.contains(ConnectivityResult.wifi) ||
        r.contains(ConnectivityResult.ethernet);
  }

  Future<bool> _waitForWifi() {
    final c = Completer<bool>();
    _wifiWait = c;
    _wifiSub?.cancel();
    _wifiSub = Connectivity().onConnectivityChanged.listen((r) {
      if ((r.contains(ConnectivityResult.wifi) ||
              r.contains(ConnectivityResult.ethernet)) &&
          !c.isCompleted) {
        c.complete(true);
      }
    });
    return c.future.whenComplete(() {
      _wifiSub?.cancel();
      _wifiSub = null;
      _wifiWait = null;
    });
  }

  /// Stops a download (or the wait for Wi-Fi). Partly downloaded files are kept
  /// so the next attempt resumes.
  void cancel() {
    _cancelRequested = true;
    final w = _wifiWait;
    if (w != null && !w.isCompleted) w.complete(false);
  }

  int _neededBytes = 0;

  /// Bytes the last failed download wanted free, shown in the "not enough space" message.
  int get neededBytes => _neededBytes;

  Future<void> download({required bool allowMobileData}) async {
    if (isBusy || isInstalled) return;
    _cancelRequested = false;
    _errorKind = null;
    _progress = 0;
    _bytesDone = 0;
    _bytesTotal = 0;
    try {
      if (!allowMobileData && !await _onWifi()) {
        _set(OfflineModelState.waitingForWifi);
        final ok = await _waitForWifi();
        if (!ok || _cancelRequested) {
          _set(OfflineModelState.notInstalled);
          return;
        }
      }
      _set(OfflineModelState.downloading);
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 20);
      try {
        final raw = await _fetchText(client, Uri.parse(manifestUrl));
        final manifest =
            ModelManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        final dir = await _dir();
        _bytesTotal = manifest.totalBytes;
        // Fail early and clearly if the phone cannot hold the rest of the pack.
        var onDisk = 0;
        for (final e in dir.listSync().whereType<File>()) {
          onDisk += e.lengthSync();
        }
        final need = (manifest.totalBytes - onDisk).clamp(0, manifest.totalBytes);
        if (!StorageCheck.enough(
            needBytes: need, freeMb: await StorageCheck.freeMb())) {
          _neededBytes = need + StorageCheck.marginBytes;
          throw const _KindException(OfflineErrorKind.notEnoughSpace);
        }
        var before = 0;
        for (final f in manifest.files) {
          await _fetchFile(client, dir, f, before);
          before += f.bytes;
        }
        await File('${dir.path}/$_marker').writeAsString(raw);
        _manifest = manifest;
        _species = null;
        _text = null;
        _progress = 1;
        _set(OfflineModelState.installed);
      } finally {
        client.close(force: true);
      }
    } on _Cancelled {
      _set(OfflineModelState.notInstalled);
    } catch (e) {
      debugPrint('OfflineModelService.download error: $e');
      _errorKind = _kindOf(e);
      _set(OfflineModelState.failed);
    }
  }

  OfflineErrorKind _kindOf(Object e) {
    if (e is _KindException) return e.kind;
    if (e is SocketException || e is HandshakeException) {
      return OfflineErrorKind.noInternet;
    }
    if (e is TimeoutException) return OfflineErrorKind.timeout;
    if (e is HttpException) return OfflineErrorKind.server;
    return OfflineErrorKind.generic;
  }

  /// GET that follows redirects by hand so a Range header survives them.
  Future<HttpClientResponse> _get(HttpClient c, Uri uri, {int from = 0}) async {
    var u = uri;
    for (var i = 0; i < 6; i++) {
      final req = await c.getUrl(u);
      req.followRedirects = false;
      if (from > 0) req.headers.set(HttpHeaders.rangeHeader, 'bytes=$from-');
      final res = await req.close();
      if (res.statusCode >= 300 && res.statusCode < 400) {
        final loc = res.headers.value(HttpHeaders.locationHeader);
        await res.drain<void>();
        if (loc == null) throw const _KindException(OfflineErrorKind.server);
        u = u.resolve(loc);
        continue;
      }
      return res;
    }
    throw const _KindException(OfflineErrorKind.server);
  }

  Future<String> _fetchText(HttpClient c, Uri uri) async {
    final res = await _get(c, uri);
    if (res.statusCode != 200) {
      await res.drain<void>();
      throw const _KindException(OfflineErrorKind.server);
    }
    return utf8.decode(await res.fold<List<int>>([], (a, b) => a..addAll(b)));
  }

  Future<String> _sha(File f) async =>
      (await sha256.bind(f.openRead()).first).toString();

  Future<void> _fetchFile(
      HttpClient client, Directory dir, ModelFile f, int before) async {
    final target = File('${dir.path}/${f.name}');
    if (await target.exists() &&
        await target.length() == f.bytes &&
        await _sha(target) == f.sha256) {
      _bytesDone = before + f.bytes;
      _tick(force: true);
      return;
    }
    final part = File('${target.path}.part');
    var have = await part.exists() ? await part.length() : 0;
    if (have > f.bytes) {
      await part.delete();
      have = 0;
    }
    if (have < f.bytes) {
      final res = await _get(client, Uri.parse(f.url), from: have);
      if (res.statusCode == 200 || res.statusCode == 206) {
        var mode = FileMode.append;
        if (res.statusCode == 200 && have > 0) {
          have = 0; // the server ignored the Range header: start again
          mode = FileMode.write;
        }
        final sink = part.openWrite(mode: mode);
        try {
          await for (final chunk in res) {
            if (_cancelRequested) throw const _Cancelled();
            sink.add(chunk);
            have += chunk.length;
            _bytesDone = before + have;
            _tick();
          }
          await sink.flush();
        } finally {
          await sink.close();
        }
      } else {
        await res.drain<void>();
        if (res.statusCode != 416) {
          throw const _KindException(OfflineErrorKind.server);
        }
      }
    }
    if (await part.length() != f.bytes) {
      throw const _KindException(OfflineErrorKind.incomplete);
    }
    if (await _sha(part) != f.sha256) {
      await part.delete();
      throw const _KindException(OfflineErrorKind.damaged);
    }
    await part.rename(target.path);
    _bytesDone = before + f.bytes;
    _tick(force: true);
  }

  DateTime _lastTick = DateTime.fromMillisecondsSinceEpoch(0);
  void _tick({bool force = false}) {
    final now = DateTime.now();
    if (!force && now.difference(_lastTick).inMilliseconds < 150) return;
    _lastTick = now;
    _progress = _bytesTotal == 0 ? 0 : _bytesDone / _bytesTotal;
    notifyListeners();
  }

  /// Deletes the downloaded pack.
  Future<void> remove() async {
    try {
      final dir = await _dir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      debugPrint('OfflineModelService.remove error: $e');
    }
    _manifest = null;
    _species = null;
    _text = null;
    _progress = 0;
    _set(OfflineModelState.notInstalled);
  }

  /// Identifies the plant in [imagePath] on this phone. Loads the model, runs it
  /// once and releases it again so it does not keep hundreds of MB in memory.
  Future<IdentifyResult> identify(String imagePath) async {
    final m = _manifest;
    if (m == null || !isInstalled) {
      throw StateError('The offline model is not installed.');
    }
    final dir = await _dir();
    _species ??= (jsonDecode(
            await File('${dir.path}/$_speciesFile').readAsString()) as List)
        .map((e) => e as String)
        .toList();
    _text ??= decodeFp16(await File('${dir.path}/$_textFile').readAsBytes());
    final species = _species!;
    final text = _text!;
    if (text.length != species.length * m.embeddingDim) {
      throw StateError('The offline model files do not match.');
    }

    final input = await compute(
      preprocessForModel,
      PreprocessJob(imagePath, m.inputSize, m.mean, m.std),
    );
    final session = await OnnxRuntime().createSession(
      '${dir.path}/$_modelFile',
      options: OrtSessionOptions(
        intraOpNumThreads: math.max(1, math.min(4, Platform.numberOfProcessors)),
      ),
    );
    OrtValue? tensor;
    Map<String, OrtValue>? outs;
    try {
      tensor = await OrtValue.fromList(
          input, [1, 3, m.inputSize, m.inputSize]);
      outs = await session.run({'image': tensor});
      final flat = await outs['emb']!.asFlattenedList();
      final emb = flat.map((e) => (e as num).toDouble()).toList();
      return scoreEmbedding(
        embedding: emb,
        textMatrix: text,
        species: species,
        dim: m.embeddingDim,
        logitScale: m.logitScale,
        acceptCosine: m.acceptCosine,
        confidentProb: m.confidentProb,
      );
    } finally {
      await tensor?.dispose();
      if (outs != null) {
        for (final v in outs.values) {
          await v.dispose();
        }
      }
      await session.close();
    }
  }
}
