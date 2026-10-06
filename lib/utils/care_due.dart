import '../models/care_log_model.dart';
import '../models/plant_model.dart';

DateTime? nextCareDate(Plant p, CareType t) {
  switch (t) {
    case CareType.water:
      return p.nextWaterDate;
    case CareType.fertilize:
      return p.nextFertilizeDate;
    case CareType.mist:
      return p.nextMistDate;
    case CareType.repot:
      return p.nextRepotDate;
    case CareType.prune:
      return p.nextPruneDate;
    case CareType.treat:
      return p.nextTreatDate;
  }
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// The most urgent care a plant needs, plus how many other tasks are due.
class DueCare {
  final Plant plant;
  final CareType type;
  final DateTime due;
  final int others;

  const DueCare({
    required this.plant,
    required this.type,
    required this.due,
    this.others = 0,
  });

  int get daysLate => _day(DateTime.now()).difference(_day(due)).inDays;
  bool get isOverdue => daysLate > 0;
  int get daysUntil => _day(due).difference(_day(DateTime.now())).inDays;

  String get statusLabel => isOverdue ? 'Overdue ${daysLate}d' : 'Today';

  String get whenLabel {
    final n = daysUntil;
    if (n <= 0) return 'today';
    if (n == 1) return 'tomorrow';
    return 'in $n days';
  }
}

/// One entry per plant that has care due today or overdue, most urgent first.
List<DueCare> dueCare(List<Plant> plants) {
  final endOfToday = _day(DateTime.now()).add(const Duration(days: 1));
  final out = <DueCare>[];
  for (final p in plants) {
    final due = <MapEntry<CareType, DateTime>>[];
    for (final t in CareType.values) {
      final d = nextCareDate(p, t);
      if (d != null && d.isBefore(endOfToday)) due.add(MapEntry(t, d));
    }
    if (due.isEmpty) continue;
    due.sort((a, b) => a.value.compareTo(b.value));
    out.add(DueCare(
      plant: p,
      type: due.first.key,
      due: due.first.value,
      others: due.length - 1,
    ));
  }
  out.sort((a, b) => a.due.compareTo(b.due));
  return out;
}

/// The soonest care after today, used for the "all caught up" tile.
DueCare? nextUpcoming(List<Plant> plants) {
  final endOfToday = _day(DateTime.now()).add(const Duration(days: 1));
  DueCare? best;
  for (final p in plants) {
    for (final t in CareType.values) {
      final d = nextCareDate(p, t);
      if (d == null || d.isBefore(endOfToday)) continue;
      if (best == null || d.isBefore(best.due)) {
        best = DueCare(plant: p, type: t, due: d);
      }
    }
  }
  return best;
}

int? careFrequency(Plant p, CareType t) {
  switch (t) {
    case CareType.water:
      return p.waterFrequencyDays;
    case CareType.fertilize:
      return p.fertilizeFrequencyDays;
    case CareType.mist:
      return p.mistFrequencyDays;
    case CareType.repot:
      return p.repotFrequencyDays;
    case CareType.prune:
      return p.pruneFrequencyDays;
    case CareType.treat:
      return p.treatFrequencyDays;
  }
}

/// A copy of [p] with one care schedule changed. Passing null removes that
/// schedule (Plant.copyWith cannot clear a value).
Plant withCareFrequency(Plant p, CareType t, int? days) {
  int? pick(CareType x) => x == t ? days : careFrequency(p, x);
  return Plant(
    id: p.id,
    name: p.name,
    species: p.species,
    roomId: p.roomId,
    acquiredDate: p.acquiredDate,
    photos: p.photos,
    careLogs: p.careLogs,
    measurements: p.measurements,
    notes: p.notes,
    isDead: p.isDead,
    isWishlist: p.isWishlist,
    createdAt: p.createdAt,
    waterFrequencyDays: pick(CareType.water),
    fertilizeFrequencyDays: pick(CareType.fertilize),
    mistFrequencyDays: pick(CareType.mist),
    repotFrequencyDays: pick(CareType.repot),
    pruneFrequencyDays: pick(CareType.prune),
    treatFrequencyDays: pick(CareType.treat),
  );
}

/// Every scheduled care after today, soonest first (one entry per plant and
/// care type).
List<DueCare> upcomingCare(List<Plant> plants) {
  final endOfToday = _day(DateTime.now()).add(const Duration(days: 1));
  final out = <DueCare>[];
  for (final p in plants) {
    for (final t in CareType.values) {
      final d = nextCareDate(p, t);
      if (d == null || d.isBefore(endOfToday)) continue;
      out.add(DueCare(plant: p, type: t, due: d));
    }
  }
  out.sort((a, b) => a.due.compareTo(b.due));
  return out;
}
