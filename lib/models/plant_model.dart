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
  // SURGICAL ADDITION: repot/prune/treat previously had no frequency
  // fields at all, so PlantProvider could only ever schedule reminders
  // for water/fertilize/mist — the other 3 of the app's advertised
  // 6 care types silently never got a reminder. Mirrors the existing
  // water/fertilize/mist fields exactly.
  final int? repotFrequencyDays;
  final int? pruneFrequencyDays;
  final int? treatFrequencyDays;

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
    this.repotFrequencyDays,
    this.pruneFrequencyDays,
    this.treatFrequencyDays,
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
    int? repotFrequencyDays,
    int? pruneFrequencyDays,
    int? treatFrequencyDays,
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
      fertilizeFrequencyDays:
          fertilizeFrequencyDays ?? this.fertilizeFrequencyDays,
      mistFrequencyDays: mistFrequencyDays ?? this.mistFrequencyDays,
      repotFrequencyDays: repotFrequencyDays ?? this.repotFrequencyDays,
      pruneFrequencyDays: pruneFrequencyDays ?? this.pruneFrequencyDays,
      treatFrequencyDays: treatFrequencyDays ?? this.treatFrequencyDays,
    );
  }

  DateTime? _nextDateFor(CareType type, int? frequencyDays) {
    final logs = careLogs.where((l) => l.type == type).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (frequencyDays == null) return null;
    // With no care logged yet, the schedule starts from the day the plant was
    // added, so reminders begin immediately instead of after the first log.
    final anchor = logs.isEmpty ? acquiredDate : logs.first.date;
    return anchor.add(Duration(days: frequencyDays));
  }

  DateTime? get nextWaterDate =>
      _nextDateFor(CareType.water, waterFrequencyDays);
  DateTime? get nextFertilizeDate =>
      _nextDateFor(CareType.fertilize, fertilizeFrequencyDays);
  DateTime? get nextMistDate => _nextDateFor(CareType.mist, mistFrequencyDays);
  DateTime? get nextRepotDate =>
      _nextDateFor(CareType.repot, repotFrequencyDays);
  DateTime? get nextPruneDate =>
      _nextDateFor(CareType.prune, pruneFrequencyDays);
  DateTime? get nextTreatDate =>
      _nextDateFor(CareType.treat, treatFrequencyDays);

  bool get isOverdue {
    final now = DateTime.now();
    for (final next in [
      nextWaterDate,
      nextFertilizeDate,
      nextMistDate,
      nextRepotDate,
      nextPruneDate,
      nextTreatDate,
    ]) {
      if (next != null && next.isBefore(now)) return true;
    }
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
        'repotFrequencyDays': repotFrequencyDays,
        'pruneFrequencyDays': pruneFrequencyDays,
        'treatFrequencyDays': treatFrequencyDays,
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
        fertilizeFrequencyDays:
            (json['fertilizeFrequencyDays'] as num?)?.toInt(),
        mistFrequencyDays: (json['mistFrequencyDays'] as num?)?.toInt(),
        repotFrequencyDays: (json['repotFrequencyDays'] as num?)?.toInt(),
        pruneFrequencyDays: (json['pruneFrequencyDays'] as num?)?.toInt(),
        treatFrequencyDays: (json['treatFrequencyDays'] as num?)?.toInt(),
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
