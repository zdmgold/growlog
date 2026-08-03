import 'photo_entry_model.dart';
import 'care_log_model.dart';
import 'measurement_model.dart';

class Plant {
  final String id;
  final String name;
  final String? species;
  final String? roomId;
  final DateTime acquiredDate;
  final List<PhotoEntry> photos;
  final List<CareLog> careLogs;
  final List<Measurement> measurements;
  final String? notes;
  final bool isDead;
  final bool isWishlist;
  final DateTime createdAt;
  final int? waterFrequencyDays;
  final int? fertilizeFrequencyDays;
  final int? mistFrequencyDays;

  const Plant({
    required this.id,
    required this.name,
    this.species,
    this.roomId,
    required this.acquiredDate,
    this.photos = const [],
    this.careLogs = const [],
    this.measurements = const [],
    this.notes,
    this.isDead = false,
    this.isWishlist = false,
    required this.createdAt,
    this.waterFrequencyDays,
    this.fertilizeFrequencyDays,
    this.mistFrequencyDays,
  });

  Plant copyWith({
    String? id,
    String? name,
    String? species,
    String? roomId,
    DateTime? acquiredDate,
    List<PhotoEntry>? photos,
    List<CareLog>? careLogs,
    List<Measurement>? measurements,
    String? notes,
    bool? isDead,
    bool? isWishlist,
    DateTime? createdAt,
    int? waterFrequencyDays,
    int? fertilizeFrequencyDays,
    int? mistFrequencyDays,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      roomId: roomId ?? this.roomId,
      acquiredDate: acquiredDate ?? this.acquiredDate,
      photos: photos ?? this.photos,
      careLogs: careLogs ?? this.careLogs,
      measurements: measurements ?? this.measurements,
      notes: notes ?? this.notes,
      isDead: isDead ?? this.isDead,
      isWishlist: isWishlist ?? this.isWishlist,
      createdAt: createdAt ?? this.createdAt,
      waterFrequencyDays: waterFrequencyDays ?? this.waterFrequencyDays,
      fertilizeFrequencyDays: fertilizeFrequencyDays ?? this.fertilizeFrequencyDays,
      mistFrequencyDays: mistFrequencyDays ?? this.mistFrequencyDays,
    );
  }

  DateTime? get nextWaterDate {
    final logs = careLogs.where((l) => l.type == CareType.water).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (logs.isEmpty || waterFrequencyDays == null) return null;
    return logs.first.date.add(Duration(days: waterFrequencyDays!));
  }

  DateTime? get nextFertilizeDate {
    final logs = careLogs.where((l) => l.type == CareType.fertilize).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (logs.isEmpty || fertilizeFrequencyDays == null) return null;
    return logs.first.date.add(Duration(days: fertilizeFrequencyDays!));
  }

  DateTime? get nextMistDate {
    final logs = careLogs.where((l) => l.type == CareType.mist).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (logs.isEmpty || mistFrequencyDays == null) return null;
    return logs.first.date.add(Duration(days: mistFrequencyDays!));
  }

  bool get isOverdue {
    final now = DateTime.now();
    final nw = nextWaterDate;
    if (nw != null && nw.isBefore(now)) return true;
    final nf = nextFertilizeDate;
    if (nf != null && nf.isBefore(now)) return true;
    final nm = nextMistDate;
    if (nm != null && nm.isBefore(now)) return true;
    return false;
  }

  PhotoEntry? get latestPhoto {
    if (photos.isEmpty) return null;
    return photos.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  PhotoEntry? get firstPhoto {
    if (photos.isEmpty) return null;
    return photos.reduce((a, b) => a.date.isBefore(b.date) ? a : b);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'species': species,
    'roomId': roomId,
    'acquiredDate': acquiredDate.toIso8601String(),
    'photos': photos.map((p) => p.toJson()).toList(),
    'careLogs': careLogs.map((l) => l.toJson()).toList(),
    'measurements': measurements.map((m) => m.toJson()).toList(),
    'notes': notes,
    'isDead': isDead ? 1 : 0,
    'isWishlist': isWishlist ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
    'waterFrequencyDays': waterFrequencyDays,
    'fertilizeFrequencyDays': fertilizeFrequencyDays,
    'mistFrequencyDays': mistFrequencyDays,
  };

  factory Plant.fromJson(Map<String, dynamic> json) => Plant(
    id: json['id'] as String,
    name: json['name'] as String,
    species: json['species'] as String?,
    roomId: json['roomId'] as String?,
    acquiredDate: DateTime.parse(json['acquiredDate'] as String),
    photos: (json['photos'] as List<dynamic>? ?? [])
        .map((e) => PhotoEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    careLogs: (json['careLogs'] as List<dynamic>? ?? [])
        .map((e) => CareLog.fromJson(e as Map<String, dynamic>))
        .toList(),
    measurements: (json['measurements'] as List<dynamic>? ?? [])
        .map((e) => Measurement.fromJson(e as Map<String, dynamic>))
        .toList(),
    notes: json['notes'] as String?,
    isDead: (json['isDead'] as num?)?.toInt() == 1,
    isWishlist: (json['isWishlist'] as num?)?.toInt() == 1,
    createdAt: DateTime.parse(json['createdAt'] as String),
    waterFrequencyDays: (json['waterFrequencyDays'] as num?)?.toInt(),
    fertilizeFrequencyDays: (json['fertilizeFrequencyDays'] as num?)?.toInt(),
    mistFrequencyDays: (json['mistFrequencyDays'] as num?)?.toInt(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Plant &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
