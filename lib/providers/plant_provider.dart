import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/plant_model.dart';
import '../models/room_model.dart';
import '../models/care_log_model.dart';
import '../models/photo_entry_model.dart';
import '../models/measurement_model.dart';
import '../services/local_storage.dart';
import '../services/notification_service.dart';

/// SURGICAL FIX (Fix Phase A): previously `_rooms` was a plain field
/// sitting outside the ValueNotifier's `value` (a bare `List<Plant>`),
/// with room changes only reaching listeners via a direct
/// `notifyListeners()` call. That worked incidentally, but it meant
/// `rooms` was not actually part of the notifier's state — anything
/// that snapshots or compares `value` (or a future ValueListenableBuilder
/// keyed strictly to value equality) would miss room-only changes.
/// Wrapping both lists in one immutable `PlantState` makes rooms a real,
/// first-class part of the notifier's value.
@immutable
class PlantState {
  final List<Plant> plants;
  final List<Room> rooms;

  const PlantState({this.plants = const [], this.rooms = const []});

  PlantState copyWith({List<Plant>? plants, List<Room>? rooms}) {
    return PlantState(
      plants: plants ?? this.plants,
      rooms: rooms ?? this.rooms,
    );
  }
}

class PlantProvider extends ValueNotifier<PlantState> {
  final LocalStorage _storage;

  // SURGICAL ADDITION: async image-existence cache. Widgets previously
  // called `File(path).existsSync()` directly during build, which is a
  // synchronous disk I/O call on every rebuild/scroll. This cache is
  // populated once (on load and after each new photo) so widgets can
  // read a plain bool instantly instead of hitting disk.
  final Map<String, bool> _imageExistsCache = {};

  // SURGICAL ADDITION: undo support. Holds the most recently deleted
  // plant (and its position in the DB via createdAt ordering) so the
  // UI can offer a "3s undo" SnackBar instead of deleting immediately
  // and irreversibly.
  Plant? _lastDeleted;

  PlantProvider(this._storage) : super(const PlantState()) {
    _load();
  }

  List<Room> get rooms => List.unmodifiable(value.rooms);

  List<Plant> get activePlants =>
      value.plants.where((p) => !p.isDead && !p.isWishlist).toList();
  List<Plant> get wishlist =>
      value.plants.where((p) => p.isWishlist).toList();
  List<Plant> get deadPlants =>
      value.plants.where((p) => p.isDead).toList();
  List<Plant> get overduePlants =>
      activePlants.where((p) => p.isOverdue).toList();

  /// Returns null if existence hasn't been checked yet (widgets should
  /// show a skeleton loader in that case), otherwise the cached result.
  bool? imageExists(String path) => _imageExistsCache[path];

  Future<void> _load() async {
    try {
      var rooms = await _storage.getRooms();
      if (rooms.isEmpty) {
        rooms = [
          const Room(id: 'living', name: 'Living Room', sortOrder: 0),
          const Room(id: 'bedroom', name: 'Bedroom', sortOrder: 1),
          const Room(id: 'kitchen', name: 'Kitchen', sortOrder: 2),
          const Room(id: 'balcony', name: 'Balcony', sortOrder: 3),
        ];
        for (final room in rooms) {
          await _storage.saveRoom(room);
        }
      }
      final plants = await _storage.getPlants();
      value = PlantState(plants: plants, rooms: rooms);
      await _refreshImageCache(plants);
    } catch (e) {
      debugPrint('PlantProvider._load error: $e');
      value = const PlantState();
    }
  }

  /// SURGICAL ADDITION: public reload for pull-to-refresh. Re-reads
  /// everything from storage without discarding the in-memory image
  /// cache for paths that are unchanged.
  Future<void> reload() async {
    await _load();
  }

  Future<void> _refreshImageCache(List<Plant> plants) async {
    for (final plant in plants) {
      for (final photo in plant.photos) {
        if (_imageExistsCache.containsKey(photo.path)) continue;
        _imageExistsCache[photo.path] = await File(photo.path).exists();
      }
    }
    notifyListeners();
  }

  Future<void> addPlant(Plant plant) async {
    try {
      await _storage.savePlant(plant);
      final plants = await _storage.getPlants();
      value = value.copyWith(plants: plants);
      _scheduleRemindersForPlant(plant);
    } catch (e) {
      debugPrint('PlantProvider.addPlant error: $e');
      throw Exception('Failed to add plant');
    }
  }

  Future<void> updatePlant(Plant updated) async {
    try {
      await _storage.savePlant(updated);
      final plants = await _storage.getPlants();
      value = value.copyWith(plants: plants);
      _scheduleRemindersForPlant(updated);
    } catch (e) {
      debugPrint('PlantProvider.updatePlant error: $e');
      throw Exception('Failed to update plant');
    }
  }

  /// SURGICAL FIX: previously deleted immediately and irreversibly.
  /// Now caches the plant before deleting so `restorePlant()` can bring
  /// it back — pairs with a "Undo" SnackBar in the UI (Fix Phase B /
  /// premium feature #3).
  Future<void> deletePlant(String id) async {
    try {
      final plant = getPlant(id);
      await _storage.deletePlant(id);
      await _cancelRemindersForPlant(id);
      _lastDeleted = plant;
      final plants = await _storage.getPlants();
      value = value.copyWith(plants: plants);
    } catch (e) {
      debugPrint('PlantProvider.deletePlant error: $e');
      throw Exception('Failed to delete plant');
    }
  }

  /// Restores the plant most recently removed via [deletePlant]. No-op
  /// if nothing has been deleted yet, or if undo was already used.
  Future<void> restorePlant() async {
    final plant = _lastDeleted;
    if (plant == null) return;
    try {
      await _storage.savePlant(plant);
      _lastDeleted = null;
      final plants = await _storage.getPlants();
      value = value.copyWith(plants: plants);
      _scheduleRemindersForPlant(plant);
    } catch (e) {
      debugPrint('PlantProvider.restorePlant error: $e');
      throw Exception('Failed to restore plant');
    }
  }

  Future<void> addCareLog(String plantId, CareLog log) async {
    try {
      final idx = value.plants.indexWhere((p) => p.id == plantId);
      if (idx == -1) return;
      final plant = value.plants[idx];
      final updated = plant.copyWith(careLogs: [...plant.careLogs, log]);
      await _storage.savePlant(updated);
      final plants = await _storage.getPlants();
      value = value.copyWith(plants: plants);
      _scheduleRemindersForPlant(updated);
    } catch (e) {
      debugPrint('PlantProvider.addCareLog error: $e');
      throw Exception('Failed to log care');
    }
  }

  Future<void> addPhoto(String plantId, PhotoEntry photo) async {
    try {
      final idx = value.plants.indexWhere((p) => p.id == plantId);
      if (idx == -1) return;
      final plant = value.plants[idx];
      final updated = plant.copyWith(photos: [...plant.photos, photo]);
      await _storage.savePlant(updated);
      final plants = await _storage.getPlants();
      value = value.copyWith(plants: plants);
      _imageExistsCache[photo.path] = await File(photo.path).exists();
      notifyListeners();
    } catch (e) {
      debugPrint('PlantProvider.addPhoto error: $e');
      throw Exception('Failed to add photo');
    }
  }

  Future<void> addMeasurement(String plantId, Measurement measurement) async {
    try {
      final idx = value.plants.indexWhere((p) => p.id == plantId);
      if (idx == -1) return;
      final plant = value.plants[idx];
      final updated =
          plant.copyWith(measurements: [...plant.measurements, measurement]);
      await _storage.savePlant(updated);
      final plants = await _storage.getPlants();
      value = value.copyWith(plants: plants);
    } catch (e) {
      debugPrint('PlantProvider.addMeasurement error: $e');
      throw Exception('Failed to add measurement');
    }
  }

  Future<void> toggleDead(String plantId) async {
    try {
      final idx = value.plants.indexWhere((p) => p.id == plantId);
      if (idx == -1) return;
      final plant = value.plants[idx];
      final updated = plant.copyWith(isDead: !plant.isDead);
      await _storage.savePlant(updated);
      final plants = await _storage.getPlants();
      value = value.copyWith(plants: plants);
      if (updated.isDead) {
        await _cancelRemindersForPlant(plantId);
      } else {
        _scheduleRemindersForPlant(updated);
      }
    } catch (e) {
      debugPrint('PlantProvider.toggleDead error: $e');
      throw Exception('Failed to update plant status');
    }
  }

  Future<void> toggleWishlist(String plantId) async {
    try {
      final idx = value.plants.indexWhere((p) => p.id == plantId);
      if (idx == -1) return;
      final plant = value.plants[idx];
      final updated = plant.copyWith(isWishlist: !plant.isWishlist);
      await _storage.savePlant(updated);
      final plants = await _storage.getPlants();
      value = value.copyWith(plants: plants);
    } catch (e) {
      debugPrint('PlantProvider.toggleWishlist error: $e');
      throw Exception('Failed to update wishlist status');
    }
  }

  Future<void> addRoom(Room room) async {
    try {
      await _storage.saveRoom(room);
      final rooms = await _storage.getRooms();
      value = value.copyWith(rooms: rooms);
    } catch (e) {
      debugPrint('PlantProvider.addRoom error: $e');
      throw Exception('Failed to add room');
    }
  }

  Future<void> updateRoom(Room updated) async {
    try {
      await _storage.saveRoom(updated);
      final rooms = await _storage.getRooms();
      value = value.copyWith(rooms: rooms);
    } catch (e) {
      debugPrint('PlantProvider.updateRoom error: $e');
      throw Exception('Failed to update room');
    }
  }

  Future<void> deleteRoom(String id) async {
    try {
      await _storage.deleteRoom(id);
      final rooms = await _storage.getRooms();
      final plants = await _storage.getPlants();
      value = PlantState(plants: plants, rooms: rooms);
    } catch (e) {
      debugPrint('PlantProvider.deleteRoom error: $e');
      throw Exception('Failed to delete room');
    }
  }

  List<Plant> plantsInRoom(String? roomId) {
    return activePlants.where((p) => p.roomId == roomId).toList();
  }

  Plant? getPlant(String id) {
    try {
      return value.plants.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.clearAll();
      await NotificationService.cancelAllReminders();
      _imageExistsCache.clear();
      _lastDeleted = null;
      value = const PlantState();
    } catch (e) {
      debugPrint('PlantProvider.clearAll error: $e');
      throw Exception('Failed to clear all data');
    }
  }

  /// SURGICAL FIX: previously only scheduled water/fertilize/mist.
  /// Repot/prune/treat are 3 of the app's advertised 6 care types and
  /// silently never got a reminder. Now schedules all 6 the same way.
  void _scheduleRemindersForPlant(Plant plant) {
    if (plant.isDead || plant.isWishlist) {
      _cancelRemindersForPlant(plant.id);
      return;
    }

    final now = DateTime.now();

    final schedule = <String, ({DateTime? date, String title, String body})>{
      'water': (
        date: plant.nextWaterDate,
        title: 'Water ${plant.name}',
        body: 'Time to water your ${plant.species ?? plant.name}',
      ),
      'fertilize': (
        date: plant.nextFertilizeDate,
        title: 'Fertilize ${plant.name}',
        body: 'Time to fertilize your ${plant.species ?? plant.name}',
      ),
      'mist': (
        date: plant.nextMistDate,
        title: 'Mist ${plant.name}',
        body: 'Time to mist your ${plant.species ?? plant.name}',
      ),
      'repot': (
        date: plant.nextRepotDate,
        title: 'Repot ${plant.name}',
        body: 'Time to repot your ${plant.species ?? plant.name}',
      ),
      'prune': (
        date: plant.nextPruneDate,
        title: 'Prune ${plant.name}',
        body: 'Time to prune your ${plant.species ?? plant.name}',
      ),
      'treat': (
        date: plant.nextTreatDate,
        title: 'Treat ${plant.name}',
        body: 'Time to treat your ${plant.species ?? plant.name}',
      ),
    };

    for (final entry in schedule.entries) {
      final date = entry.value.date;
      if (date != null && date.isAfter(now)) {
        NotificationService.scheduleCareReminder(
          id: NotificationService.generateCareNotificationId(
              plant.id, entry.key),
          title: entry.value.title,
          body: entry.value.body,
          scheduledDate: date,
        );
      }
    }
  }

  Future<void> _cancelRemindersForPlant(String plantId) async {
    for (final type in [
      'water',
      'fertilize',
      'mist',
      'repot',
      'prune',
      'treat',
    ]) {
      await NotificationService.cancelReminder(
        NotificationService.generateCareNotificationId(plantId, type),
      );
    }
  }
}
