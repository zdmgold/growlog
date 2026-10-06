import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_client.dart';
import 'ai_providers.dart';

class ConnectResult {
  final List<String> candidates;
  final String model;
  final bool vision;
  const ConnectResult({
    required this.candidates,
    required this.model,
    required this.vision,
  });
}

/// The user's chosen provider, key and model. Keys live in encrypted storage
/// on the phone and are only ever sent to the provider they belong to.
class AiSettings extends ChangeNotifier {
  AiSettings._();
  static final AiSettings instance = AiSettings._();

  static const _secure = FlutterSecureStorage();
  static const _kProvider = 'ai_provider';
  static const _kModel = 'ai_model';
  static const _kVision = 'ai_vision';

  String? _providerId;
  String? _model;
  bool _vision = false;
  String? _key;
  List<String> _candidates = const [];

  AiProvider? get provider => providerById(_providerId);
  String? get model => _model;
  bool get supportsVision => _vision;
  List<String> get candidates => _candidates;
  bool get isConfigured =>
      provider != null && (_key?.isNotEmpty ?? false) && (_model?.isNotEmpty ?? false);

  AiClient? get client {
    final p = provider;
    if (!isConfigured || p == null) return null;
    return AiClient(provider: p, apiKey: _key!, model: _model!);
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _providerId = prefs.getString(_kProvider);
      _model = prefs.getString(_kModel);
      _vision = prefs.getBool(_kVision) ?? false;
      if (_providerId != null) {
        _key = await _secure.read(key: 'ai_key_$_providerId');
      }
    } catch (e) {
      debugPrint('AiSettings.load error: $e');
    }
    notifyListeners();
  }

  /// Validates the key, finds a model that works, and saves everything.
  Future<ConnectResult> connect(
    AiProvider p,
    String rawKey, {
    void Function(String status)? onStatus,
  }) async {
    final key = rawKey.trim();
    if (key.isEmpty) throw const AiException('Paste your key first.');

    onStatus?.call('Checking your key…');
    final models = await AiClient.listModels(p, key);
    final ranked = rankModels(p, models);
    if (ranked.isEmpty) {
      throw const AiException('This key has no usable models.');
    }

    final testImage = _testJpeg();
    String? working;
    var vision = false;
    AiException? lastError;

    for (final id in ranked) {
      onStatus?.call('Testing $id…');
      try {
        await AiClient(provider: p, apiKey: key, model: id).complete(
          messages: const [AiMessage('user', 'Reply with the single word OK.')],
          image: testImage,
          maxTokens: 20,
        );
        working = id;
        vision = true;
        break;
      } on AiException catch (e) {
        if (e.isAuth) rethrow;
        lastError = e;
      }
    }

    if (working == null) {
      onStatus?.call('Checking text-only access…');
      try {
        await AiClient(provider: p, apiKey: key, model: ranked.first).complete(
          messages: const [AiMessage('user', 'Reply with the single word OK.')],
          maxTokens: 20,
        );
        working = ranked.first;
      } on AiException catch (e) {
        throw lastError ?? e;
      }
    }

    await _save(p, key, working, vision, ranked);
    return ConnectResult(candidates: ranked, model: working, vision: vision);
  }

  Future<void> _save(
    AiProvider p,
    String key,
    String model,
    bool vision,
    List<String> candidates,
  ) async {
    _providerId = p.id;
    _key = key;
    _model = model;
    _vision = vision;
    _candidates = candidates;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProvider, p.id);
      await prefs.setString(_kModel, model);
      await prefs.setBool(_kVision, vision);
      await _secure.write(key: 'ai_key_${p.id}', value: key);
    } catch (e) {
      debugPrint('AiSettings._save error: $e');
    }
    notifyListeners();
  }

  Future<void> selectModel(String model) async {
    _model = model;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kModel, model);
    } catch (e) {
      debugPrint('AiSettings.selectModel error: $e');
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    final id = _providerId;
    _providerId = null;
    _key = null;
    _model = null;
    _vision = false;
    _candidates = const [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProvider);
      await prefs.remove(_kModel);
      await prefs.remove(_kVision);
      if (id != null) await _secure.delete(key: 'ai_key_$id');
    } catch (e) {
      debugPrint('AiSettings.disconnect error: $e');
    }
    notifyListeners();
  }

  static Uint8List _testJpeg() {
    final image = img.Image(width: 64, height: 64);
    img.fill(image, color: img.ColorRgb8(46, 125, 79));
    return Uint8List.fromList(img.encodeJpg(image, quality: 80));
  }
}

/// Orders a provider's models so likely vision-capable, current ones come
/// first. This is a heuristic; the connect step tests each candidate for real.
@visibleForTesting
List<String> rankModels(AiProvider p, List<AiModel> models) {
  final bad = RegExp(
    r'embed|tts|whisper|transcribe|audio|realtime|moderation|imagen|veo|dall|guard|rerank|ocr|imagine|image-gen|search|gpt-3\.5-turbo-instruct|codex',
    caseSensitive: false,
  );
  final list = models.where((m) => !bad.hasMatch(m.id)).toList();

  int score(AiModel m) {
    final id = m.id.toLowerCase();
    var s = 0;
    if (m.imageInput == true) s += 50;
    if (m.imageInput == false) s -= 50;
    switch (p.id) {
      case 'anthropic':
        if (id.contains('sonnet')) s += 30;
        if (id.contains('haiku')) s += 20;
        if (id.contains('opus')) s += 10;
        break;
      case 'gemini':
        if (!id.contains('gemini')) s -= 40;
        if (id.contains('flash')) s += 30;
        if (id.contains('lite')) s -= 5;
        if (id.contains('pro')) s += 15;
        if (id.contains('preview') || id.contains('exp')) s -= 10;
        break;
      case 'openai':
        if (id.startsWith('gpt-')) s += 20;
        if (id.contains('mini')) s += 15;
        if (id.contains('nano')) s += 5;
        break;
      case 'xai':
        if (id.contains('grok')) s += 20;
        if (id.contains('grok-4')) s += 10;
        if (id.contains('vision')) s += 10;
        if (id.contains('fast')) s += 5;
        break;
      case 'mistral':
        if (id.contains('pixtral')) s += 30;
        if (id.contains('medium')) s += 20;
        if (id.contains('small')) s += 15;
        if (id.contains('large')) s += 10;
        break;
      case 'groq':
        if (id.contains('scout') || id.contains('maverick')) s += 30;
        if (id.contains('llama-4')) s += 25;
        if (id.contains('qwen3.8')) s += 60;
        if (id.contains('vision')) s += 20;
        break;
      case 'openrouter':
        if (id.endsWith(':free')) s += 10;
        break;
      case 'cerebras':
        if (id.contains('qwen-3.8') ||
            id.contains('qwen3.8') ||
            id.contains('gemma-4')) {
          s += 35;
        }
        break;
    }
    return s;
  }

  list.sort((a, b) {
    final c = score(b).compareTo(score(a));
    if (c != 0) return c;
    final ta = a.created?.millisecondsSinceEpoch ?? 0;
    final tb = b.created?.millisecondsSinceEpoch ?? 0;
    if (tb != ta) return tb.compareTo(ta);
    return b.id.compareTo(a.id);
  });
  return list.take(4).map((m) => m.id).toList();
}
