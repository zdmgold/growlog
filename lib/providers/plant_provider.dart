import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../models/room_model.dart';
import '../models/care_log_model.dart';
import '../models/photo_entry_model.dart';
import '../models/measurement_model.dart';
import '../services/local_storage.dart';
import '../services/notification_service.dart';

class PlantProvider extends ValueNotifier<List<Plant>> {
  final LocalStorage _storage;
  List<Room> _rooms = [];

  PlantProvider(this._storage) : super([]) {
    _load();
  }

  List<Room> get rooms => List.unmodifiable(_rooms);

  List<Plant> get activePlants => value.where((p) => !p.isDead && !p.isWishlist).toList();
  List<Plant> get wishlist => value.where((p) => p.isWishlist).toList();
  List<Plant> get deadPlants => value.where((p) => p.isDead).toList();
  List<Plant> get overduePlants => activePlants.where((p) => p.isOverdue).toList();

  Future<void> _load() async {
    try {
      _rooms = await _storage.getRooms();
      if (_rooms.isEmpty) {
        _rooms = [
          const Room(id: 'living', name: 'Living Room', sortOrder: 0),
          const Room(id: 'bedroom', name: 'Bedroom', sortOrder: 1),
          const Room(id: 'kitchen', name: 'Kitchen', sortOrder: 2),
          const Room(id: 'balcony', name: 'Balcony', sortOrder: 3),
        ];
        for (final room in _rooms) {
          await _storage.saveRoom(room);
        }
      }
      final plants = await _storage.getPlants();
      value = plants;
    } catch (e) {
      debugPrint('PlantProvider._load error: $e');
      value = [];
    }
  }

  Future<void> addPlant(Plant plant) async {
    try {
      await _storage.savePlant(plant);
      final plants = await _storage.getPlants();
      value = plants;
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
      value = plants;
      _scheduleRemindersForPlant(updated);
    } catch (e) {
      debugPrint('PlantProvider.updatePlant error: $e');
      throw Exception('Failed to update plant');
    }
  }

  Future<void> deletePlant(String id) async {
    try {
      await _storage.deletePlant(id);
      await _cancelRemindersForPlant(id);
      final plants = await _storage.getPlants();
      value = plants;
    } catch (e) {
      debugPrint('PlantProvider.deletePlant error: $e');
      throw Exception('Failed to delete plant');
    }
  }

  Future<void> addCareLog(String plantId, CareLog log) async {
    try {
      final idx = value.indexWhere((p) => p.id == plantId);
      if (idx == -1) return;
      final plant = value[idx];
      final updated = plant.copyWith(careLogs: [...plant.careLogs, log]);
      await _storage.savePlant(updated);
      final plants = await _storage.getPlants();
      value = plants;
      _scheduleRemindersForPlant(updated);
    } catch (e) {
      debugPrint('PlantProvider.addCareLog error: $e');
      throw Exception('Failed to log care');
    }
  }

  Future<void> addPhoto(String plantId, PhotoEntry photo) async {
    try {
      final idx = value.indexWhere((p) => p.id == plantId);
      if (idx == -1) return;
      final plant = value[idx];
      final updated = plant.copyWith(photos: [...plant.photos, photo]);
      await _storage.savePlant(updated);
      final plants = await _storage.getPlants();
      value = plants;
    } catch (e) {
      debugPrint('PlantProvider.addPhoto error: $e');
      throw Exception('Failed to add photo');
    }
  }

  Future<void> addMeasurement(String plantId, Measurement measurement) async {
    try {
      final idx = value.indexWhere((p) => p.id == plantId);
      if (idx == -1) return;
      final plant = value[idx];
      final updated = plant.copyWith(measurements: [...plant.measurements, measurement]);
      await _storage.savePlant(updated);
      final plants = await _storage.getPlants();
      value = plants;
    } catch (e) {
      debugPrint('PlantProvider.addMeasurement error: $e');
      throw Exception('Failed to add measurement');
    }
  }

  Future<void> toggleDead(String plantId) async {
    try {
      final idx = value.indexWhere((p) => p.id == plantId);
      if (idx == -1) return;
      final plant = value[idx];
      final updated = plant.copyWith(isDead: !plant.isDead);
      await _storage.savePlant(updated);
      final plants = await _storage.getPlants();
      value = plants;
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
      final idx = value.indexWhere((p) => p.id == plantId);
      if (idx == -1) return;
      final plant = value[idx];
      final updated = plant.copyWith(isWishlist: !plant.isWishlist);
      await _storage.savePlant(updated);
      final plants = await _storage.getPlants();
      value = plants;
    } catch (e) {
      debugPrint('PlantProvider.toggleWishlist error: $e');
      throw Exception('Failed to update wishlist status');
    }
  }

  Future<void> addRoom(Room room) async {
    try {
      await _storage.saveRoom(room);
      _rooms = await _storage.getRooms();
      notifyListeners();
    } catch (e) {
      debugPrint('PlantProvider.addRoom error: $e');
      throw Exception('Failed to add room');
    }
  }

  Future<void> updateRoom(Room updated) async {
    try {
      await _storage.saveRoom(updated);
      _rooms = await _storage.getRooms();
      notifyListeners();
    } catch (e) {
      debugPrint('PlantProvider.updateRoom error: $e');
      throw Exception('Failed to update room');
    }
  }

  Future<void> deleteRoom(String id) async {
    try {
      await _storage.deleteRoom(id);
      _rooms = await _storage.getRooms();
      final updatedPlants = value.map((p) => p.roomId == id ? p.copyWith(roomId: null) : p).toList();
      for (final plant in updatedPlants) {
        if (plant.roomId == null && value.any((p) => p.id == plant.id && p.roomId != null)) {
          await _storage.savePlant(plant);
        }
      }
      final plants = await _storage.getPlants();
      value = plants;
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
      return value.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.clearAll();
      await NotificationService.cancelAllReminders();
      _rooms = [];
      value = [];
    } catch (e) {
      debugPrint('PlantProvider.clearAll error: $e');
      throw Exception('Failed to clear all data');
    }
  }

  void _scheduleRemindersForPlant(Plant plant) {
    if (plant.isDead || plant.isWishlist) {
      _cancelRemindersForPlant(plant.id);
      return;
    }

    final now = DateTime.now();

    final nextWater = plant.nextWaterDate;
    if (nextWater != null && nextWater.isAfter(now)) {
      NotificationService.scheduleCareReminder(
        id: NotificationService.generateCareNotificationId(plant.id, 'water'),
        title: 'Water ${plant.name}',
        body: 'Time to water your ${plant.species ?? plant.name}',
        scheduledDate: nextWater,
      );
    }

    final nextFertilize = plant.nextFertilizeDate;
    if (nextFertilize != null && nextFertilize.isAfter(now)) {
      NotificationService.scheduleCareReminder(
        id: NotificationService.generateCareNotificationId(plant.id, 'fertilize'),
        title: 'Fertilize ${plant.name}',
        body: 'Time to fertilize your ${plant.species ?? plant.name}',
        scheduledDate: nextFertilize,
      );
    }

    final nextMist = plant.nextMistDate;
    if (nextMist != null && nextMist.isAfter(now)) {
      NotificationService.scheduleCareReminder(
        id: NotificationService.generateCareNotificationId(plant.id, 'mist'),
        title: 'Mist ${plant.name}',
        body: 'Time to mist your ${plant.species ?? plant.name}',
        scheduledDate: nextMist,
      );
    }
  }

  Future<void> _cancelRemindersForPlant(String plantId) async {
    await NotificationService.cancelReminder(
      NotificationService.generateCareNotificationId(plantId, 'water'),
    );
    await NotificationService.cancelReminder(
      NotificationService.generateCareNotificationId(plantId, 'fertilize'),
    );
    await NotificationService.cancelReminder(
      NotificationService.generateCareNotificationId(plantId, 'mist'),
    );
  }
}
