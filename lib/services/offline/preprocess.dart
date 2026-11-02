import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class PreprocessJob {
  final String path;
  final int size;
  final List<double> mean;
  final List<double> std;
  const PreprocessJob(this.path, this.size, this.mean, this.std);
}

/// Reads a photo, fixes its orientation, centre-crops to a square, resizes and
/// normalises it into a 1x3xSxS float tensor (channel-first). Top-level so it can
/// run in a background isolate via `compute`.
Future<Float32List> preprocessForModel(PreprocessJob job) async {
  final bytes = await File(job.path).readAsBytes();
  var im = img.decodeImage(bytes);
  if (im == null) throw const FormatException('Unreadable image');
  im = img.bakeOrientation(im);
  im = im.convert(numChannels: 3);
  final side = math.min(im.width, im.height);
  im = img.copyCrop(
    im,
    x: (im.width - side) ~/ 2,
    y: (im.height - side) ~/ 2,
    width: side,
    height: side,
  );
  im = img.copyResize(
    im,
    width: job.size,
    height: job.size,
    interpolation: img.Interpolation.cubic,
  );
  final s = job.size;
  final plane = s * s;
  final out = Float32List(3 * plane);
  for (var y = 0; y < s; y++) {
    for (var x = 0; x < s; x++) {
      final p = im.getPixel(x, y);
      final i = y * s + x;
      out[i] = (p.r / 255.0 - job.mean[0]) / job.std[0];
      out[plane + i] = (p.g / 255.0 - job.mean[1]) / job.std[1];
      out[2 * plane + i] = (p.b / 255.0 - job.mean[2]) / job.std[2];
    }
  }
  return out;
}
