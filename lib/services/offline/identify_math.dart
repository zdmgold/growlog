import 'dart:math' as math;
import 'dart:typed_data';

/// Converts one IEEE half-precision value (as 16 raw bits) to a double.
double halfToDouble(int h) {
  final sign = (h >> 15) & 1;
  final exp = (h >> 10) & 0x1f;
  final frac = h & 0x3ff;
  double v;
  if (exp == 0) {
    v = frac * math.pow(2, -24).toDouble();
  } else if (exp == 31) {
    v = frac == 0 ? double.infinity : double.nan;
  } else {
    v = (1 + frac / 1024) * math.pow(2, exp - 15).toDouble();
  }
  return sign == 1 ? -v : v;
}

/// Reads a little-endian float16 byte buffer into float32 values.
Float32List decodeFp16(Uint8List bytes) {
  final n = bytes.length ~/ 2;
  final out = Float32List(n);
  final bd = ByteData.sublistView(bytes);
  for (var i = 0; i < n; i++) {
    out[i] = halfToDouble(bd.getUint16(i * 2, Endian.little));
  }
  return out;
}

class SpeciesGuess {
  final String species;
  final double probability;
  final double cosine;
  const SpeciesGuess(this.species, this.probability, this.cosine);
}

class IdentifyResult {
  /// Best guesses first.
  final List<SpeciesGuess> guesses;

  /// False when the photo does not look like any plant in the list.
  final bool accepted;

  /// True when the top guess is strong enough to show as "likely".
  final bool confident;

  const IdentifyResult({
    required this.guesses,
    required this.accepted,
    required this.confident,
  });
}

/// Scores an image embedding against species text embeddings (zero-shot).
/// [textMatrix] is row-major, one L2-normalised row of [dim] values per species.
IdentifyResult scoreEmbedding({
  required List<double> embedding,
  required Float32List textMatrix,
  required List<String> species,
  required int dim,
  required double logitScale,
  required double acceptCosine,
  required double confidentProb,
  int top = 5,
}) {
  assert(embedding.length == dim);
  assert(textMatrix.length == species.length * dim);
  var norm = 0.0;
  for (final v in embedding) {
    norm += v * v;
  }
  norm = math.sqrt(norm);
  if (norm == 0) {
    return const IdentifyResult(guesses: [], accepted: false, confident: false);
  }
  final n = species.length;
  final cos = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    var dot = 0.0;
    final base = i * dim;
    for (var j = 0; j < dim; j++) {
      dot += embedding[j] * textMatrix[base + j];
    }
    cos[i] = dot / norm;
  }
  var maxLogit = -double.infinity;
  for (final c in cos) {
    maxLogit = math.max(maxLogit, c * logitScale);
  }
  final exps = List<double>.generate(
      n, (i) => math.exp(cos[i] * logitScale - maxLogit));
  final sum = exps.fold<double>(0, (a, b) => a + b);
  final order = List<int>.generate(n, (i) => i)
    ..sort((a, b) => cos[b].compareTo(cos[a]));
  final guesses = <SpeciesGuess>[
    for (final i in order.take(math.min(top, n)))
      SpeciesGuess(species[i], exps[i] / sum, cos[i]),
  ];
  final accepted = guesses.isNotEmpty && guesses.first.cosine >= acceptCosine;
  final confident = accepted && guesses.first.probability >= confidentProb;
  return IdentifyResult(
      guesses: guesses, accepted: accepted, confident: confident);
}
