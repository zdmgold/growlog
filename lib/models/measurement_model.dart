class Measurement {
  final String id;
  final String plantId;
  final DateTime date;
  final double? height;
  final int? leafCount;
  final double? stemWidth;

  const Measurement({
    required this.id,
    required this.plantId,
    required this.date,
    this.height,
    this.leafCount,
    this.stemWidth,
  });

  Measurement copyWith({
    String? id,
    String? plantId,
    DateTime? date,
    double? height,
    int? leafCount,
    double? stemWidth,
  }) {
    return Measurement(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      date: date ?? this.date,
      height: height ?? this.height,
      leafCount: leafCount ?? this.leafCount,
      stemWidth: stemWidth ?? this.stemWidth,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'plantId': plantId,
    'date': date.toIso8601String(),
    'height': height,
    'leafCount': leafCount,
    'stemWidth': stemWidth,
  };

  factory Measurement.fromJson(Map<String, dynamic> json) => Measurement(
    id: json['id'] as String,
    plantId: json['plantId'] as String,
    date: DateTime.parse(json['date'] as String),
    height: (json['height'] as num?)?.toDouble(),
    leafCount: json['leafCount'] as int?,
    stemWidth: (json['stemWidth'] as num?)?.toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Measurement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
