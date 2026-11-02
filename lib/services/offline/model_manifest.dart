/// One downloadable file of the offline model pack.
class ModelFile {
  final String name;
  final String url;
  final int bytes;
  final String sha256;

  const ModelFile({
    required this.name,
    required this.url,
    required this.bytes,
    required this.sha256,
  });

  factory ModelFile.fromJson(Map<String, dynamic> j) => ModelFile(
        name: j['name'] as String,
        url: j['url'] as String,
        bytes: (j['bytes'] as num).toInt(),
        sha256: (j['sha256'] as String).toLowerCase(),
      );
}

/// Describes the offline identification pack: files, checksums and the numbers the
/// app needs to run the model (input size, normalisation, thresholds).
class ModelManifest {
  final int version;
  final String modelId;
  final int inputSize;
  final int embeddingDim;
  final int speciesCount;
  final List<double> mean;
  final List<double> std;
  final double logitScale;
  final double acceptCosine;
  final double confidentProb;
  final List<ModelFile> files;

  const ModelManifest({
    required this.version,
    required this.modelId,
    required this.inputSize,
    required this.embeddingDim,
    required this.speciesCount,
    required this.mean,
    required this.std,
    required this.logitScale,
    required this.acceptCosine,
    required this.confidentProb,
    required this.files,
  });

  factory ModelManifest.fromJson(Map<String, dynamic> j) {
    List<double> nums(Object? v) =>
        (v as List).map((e) => (e as num).toDouble()).toList();
    return ModelManifest(
      version: (j['version'] as num).toInt(),
      modelId: j['model_id'] as String,
      inputSize: (j['input_size'] as num).toInt(),
      embeddingDim: (j['embedding_dim'] as num).toInt(),
      speciesCount: (j['species_count'] as num).toInt(),
      mean: nums(j['mean']),
      std: nums(j['std']),
      logitScale: (j['logit_scale'] as num).toDouble(),
      acceptCosine: (j['accept_cosine'] as num).toDouble(),
      confidentProb: (j['confident_prob'] as num).toDouble(),
      files: (j['files'] as List)
          .map((e) => ModelFile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int get totalBytes => files.fold(0, (a, f) => a + f.bytes);

  ModelFile file(String name) => files.firstWhere((f) => f.name == name);
}
