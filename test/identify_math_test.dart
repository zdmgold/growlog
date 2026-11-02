import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/services/offline/identify_math.dart';
import 'package:growlog/services/offline/model_manifest.dart';

void main() {
  test('half precision values decode correctly', () {
    expect(halfToDouble(0x0000), 0.0);
    expect(halfToDouble(0x3C00), 1.0);
    expect(halfToDouble(0xC000), -2.0);
    expect(halfToDouble(0x3800), 0.5);
    expect(halfToDouble(0x7BFF), 65504.0);
    expect(halfToDouble(0x7C00), double.infinity);
  });

  test('decodeFp16 reads little-endian pairs', () {
    final bytes = Uint8List.fromList([0x00, 0x3C, 0x00, 0xC0]);
    final out = decodeFp16(bytes);
    expect(out.length, 2);
    expect(out[0], 1.0);
    expect(out[1], -2.0);
  });

  Float32List text() => Float32List.fromList([
        1, 0, 0, // species A
        0, 1, 0, // species B
        0, 0, 1, // species C
      ]);
  const names = ['A', 'B', 'C'];

  test('closest species wins and probabilities sum to about one', () {
    final r = scoreEmbedding(
      embedding: [0.9, 0.2, 0.1],
      textMatrix: text(),
      species: names,
      dim: 3,
      logitScale: 100,
      acceptCosine: 0.5,
      confidentProb: 0.6,
      top: 3,
    );
    expect(r.guesses.first.species, 'A');
    expect(r.accepted, isTrue);
    expect(r.confident, isTrue);
    final total = r.guesses.fold<double>(0, (a, g) => a + g.probability);
    expect(total, closeTo(1.0, 1e-6));
  });

  test('embedding far from every species is not accepted', () {
    final r = scoreEmbedding(
      embedding: [0.4, 0.4, 0.4],
      textMatrix: text(),
      species: names,
      dim: 3,
      logitScale: 100,
      acceptCosine: 0.9,
      confidentProb: 0.6,
    );
    expect(r.accepted, isFalse);
    expect(r.confident, isFalse);
  });

  test('a tie is accepted but not confident', () {
    final r = scoreEmbedding(
      embedding: [1, 1, 0],
      textMatrix: text(),
      species: names,
      dim: 3,
      logitScale: 100,
      acceptCosine: 0.5,
      confidentProb: 0.6,
    );
    expect(r.accepted, isTrue);
    expect(r.confident, isFalse);
  });

  test('zero embedding gives no guesses', () {
    final r = scoreEmbedding(
      embedding: [0, 0, 0],
      textMatrix: text(),
      species: names,
      dim: 3,
      logitScale: 100,
      acceptCosine: 0.5,
      confidentProb: 0.6,
    );
    expect(r.guesses, isEmpty);
    expect(r.accepted, isFalse);
  });

  test('manifest parses and totals file sizes', () {
    final m = ModelManifest.fromJson({
      'version': 1,
      'model_id': 'x',
      'input_size': 224,
      'embedding_dim': 768,
      'species_count': 107,
      'mean': [0.1, 0.2, 0.3],
      'std': [0.4, 0.5, 0.6],
      'logit_scale': 100.0,
      'accept_cosine': 0.2,
      'confident_prob': 0.5,
      'files': [
        {'name': 'a', 'url': 'u', 'bytes': 10, 'sha256': 'AB'},
        {'name': 'b', 'url': 'v', 'bytes': 5, 'sha256': 'cd'},
      ],
    });
    expect(m.totalBytes, 15);
    expect(m.file('a').sha256, 'ab');
    expect(m.mean[2], 0.3);
  });
}
