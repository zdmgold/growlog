class PhotoEntry {
  final String id;
  final String plantId;
  final DateTime date;
  final String path;
  final String? notes;
  final double? height;
  final int? leafCount;

  const PhotoEntry({
    required this.id,
    required this.plantId,
    required this.date,
    required this.path,
    this.notes,
    this.height,
    this.leafCount,
  });

  PhotoEntry copyWith({
    String? id,
    String? plantId,
    DateTime? date,
    String? path,
    String? notes,
    double? height,
    int? leafCount,
  }) {
    return PhotoEntry(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      date: date ?? this.date,
      path: path ?? this.path,
      notes: notes ?? this.notes,
      height: height ?? this.height,
      leafCount: leafCount ?? this.leafCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'plantId': plantId,
    'date': date.toIso8601String(),
    'path': path,
    'notes': notes,
    'height': height,
    'leafCount': leafCount,
  };

  factory PhotoEntry.fromJson(Map<String, dynamic> json) => PhotoEntry(
    id: json['id'] as String,
    plantId: json['plantId'] as String,
    date: DateTime.parse(json['date'] as String),
    path: json['path'] as String,
    notes: json['notes'] as String?,
    height: (json['height'] as num?)?.toDouble(),
    leafCount: json['leafCount'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
