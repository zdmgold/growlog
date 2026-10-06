import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

const int _maxSide = 1400;

/// Reads any common image file, fixes its orientation, shrinks it and returns
/// JPEG bytes. Top-level so it can run in a background isolate via `compute`.
/// If the format is not supported, the original bytes are returned unchanged.
Future<Uint8List> prepareImageForAi(String path) async {
  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  var out = img.bakeOrientation(decoded);
  if (out.width > _maxSide || out.height > _maxSide) {
    out = out.width >= out.height
        ? img.copyResize(out, width: _maxSide)
        : img.copyResize(out, height: _maxSide);
  }
  return Uint8List.fromList(img.encodeJpg(out, quality: 85));
}
