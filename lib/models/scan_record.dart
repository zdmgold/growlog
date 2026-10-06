enum ScanHealth { healthy, watch, attention }

/// One saved plant scan: what the AI saw, how healthy it looked, and the
/// care it suggested.
class ScanRecord {
  final String id;
  final String? plantId;
  final String imagePath;
  final DateTime createdAt;
  final bool isPlant;
  final String commonName;
  final String? latinName;
  final String confidence;
  final ScanHealth health;
  final String issue;
  final String severity;
  final String summary;
  final List<String> treatment;
  final List<String> prevention;
  final int? waterDays;
  final int? fertilizeDays;
  final String? light;
  final String? savedPlantId;

  const ScanRecord({
    required this.id,
    this.plantId,
    required this.imagePath,
    required this.createdAt,
    this.isPlant = true,
    required this.commonName,
    this.latinName,
    this.confidence = 'Medium',
    this.health = ScanHealth.healthy,
    this.issue = '',
    this.severity = 'None',
    this.summary = '',
    this.treatment = const [],
    this.prevention = const [],
    this.waterDays,
    this.fertilizeDays,
    this.light,
    this.savedPlantId,
  });

  bool get hasIssue => issue.trim().isNotEmpty;

  ScanRecord copyWith({String? savedPlantId, String? imagePath}) {
    return ScanRecord(
      id: id,
      plantId: plantId,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt,
      isPlant: isPlant,
      commonName: commonName,
      latinName: latinName,
      confidence: confidence,
      health: health,
      issue: issue,
      severity: severity,
      summary: summary,
      treatment: treatment,
      prevention: prevention,
      waterDays: waterDays,
      fertilizeDays: fertilizeDays,
      light: light,
      savedPlantId: savedPlantId ?? this.savedPlantId,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'plantId': plantId,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
        'isPlant': isPlant ? 1 : 0,
        'commonName': commonName,
        'latinName': latinName,
        'confidence': confidence,
        'health': health.name,
        'issue': issue,
        'severity': severity,
        'summary': summary,
        'treatment': treatment.join('\n'),
        'prevention': prevention.join('\n'),
        'waterDays': waterDays,
        'fertilizeDays': fertilizeDays,
        'light': light,
        'savedPlantId': savedPlantId,
      };

  static List<String> _lines(Object? v) {
    final s = v?.toString() ?? '';
    return s.isEmpty ? const [] : s.split('\n');
  }

  factory ScanRecord.fromMap(Map<String, Object?> m) {
    return ScanRecord(
      id: m['id'] as String,
      plantId: m['plantId'] as String?,
      imagePath: m['imagePath'] as String,
      createdAt: DateTime.parse(m['createdAt'] as String),
      isPlant: (m['isPlant'] as int? ?? 1) == 1,
      commonName: m['commonName'] as String? ?? 'Unknown plant',
      latinName: m['latinName'] as String?,
      confidence: m['confidence'] as String? ?? 'Medium',
      health: ScanHealth.values.firstWhere(
        (h) => h.name == m['health'],
        orElse: () => ScanHealth.healthy,
      ),
      issue: m['issue'] as String? ?? '',
      severity: m['severity'] as String? ?? 'None',
      summary: m['summary'] as String? ?? '',
      treatment: _lines(m['treatment']),
      prevention: _lines(m['prevention']),
      waterDays: m['waterDays'] as int?,
      fertilizeDays: m['fertilizeDays'] as int?,
      light: m['light'] as String?,
      savedPlantId: m['savedPlantId'] as String?,
    );
  }
}
