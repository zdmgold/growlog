import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/room_model.dart';
import '../models/plant_model.dart';
import '../models/photo_entry_model.dart';
import '../models/care_log_model.dart';
import '../models/measurement_model.dart';

class LocalStorage {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'growlog.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE rooms(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT,
            sortOrder INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE plants(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            species TEXT,
            roomId TEXT,
            acquiredDate TEXT NOT NULL,
            notes TEXT,
            isDead INTEGER NOT NULL DEFAULT 0,
            isWishlist INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            waterFrequencyDays INTEGER,
            fertilizeFrequencyDays INTEGER,
            mistFrequencyDays INTEGER,
            FOREIGN KEY (roomId) REFERENCES rooms(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE photos(
            id TEXT PRIMARY KEY,
            plantId TEXT NOT NULL,
            date TEXT NOT NULL,
            path TEXT NOT NULL,
            notes TEXT,
            height REAL,
            leafCount INTEGER,
            FOREIGN KEY (plantId) REFERENCES plants(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE care_logs(
            id TEXT PRIMARY KEY,
            plantId TEXT NOT NULL,
            type TEXT NOT NULL,
            date TEXT NOT NULL,
            notes TEXT,
            FOREIGN KEY (plantId) REFERENCES plants(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE measurements(
            id TEXT PRIMARY KEY,
            plantId TEXT NOT NULL,
            date TEXT NOT NULL,
            height REAL,
            leafCount INTEGER,
            stemWidth REAL,
            FOREIGN KEY (plantId) REFERENCES plants(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // Rooms
  Future<List<Room>> getRooms() async {
    final db = await database;
    final maps = await db.query('rooms', orderBy: 'sortOrder ASC');
    return maps.map((m) => Room.fromJson(m)).toList();
  }

  Future<void> saveRoom(Room room) async {
    final db = await database;
    await db.insert(
      'rooms',
      room.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteRoom(String id) async {
    final db = await database;
    await db.delete('rooms', where: 'id = ?', whereArgs: [id]);
    await db.update('plants', {'roomId': null}, where: 'roomId = ?', whereArgs: [id]);
  }

  // Plants with nested data
  Future<List<Plant>> getPlants() async {
    final db = await database;
    final plantMaps = await db.query('plants', orderBy: 'createdAt DESC');
    final plants = <Plant>[];

    for (final map in plantMaps) {
      final id = map['id'] as String;
      final photos = await _getPhotos(id);
      final careLogs = await _getCareLogs(id);
      final measurements = await _getMeasurements(id);

      plants.add(Plant(
        id: id,
        name: map['name'] as String,
        species: map['species'] as String?,
        roomId: map['roomId'] as String?,
        acquiredDate: DateTime.parse(map['acquiredDate'] as String),
        photos: photos,
        careLogs: careLogs,
        measurements: measurements,
        notes: map['notes'] as String?,
        isDead: (map['isDead'] as num) == 1,
        isWishlist: (map['isWishlist'] as num) == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
        waterFrequencyDays: (map['waterFrequencyDays'] as num?)?.toInt(),
        fertilizeFrequencyDays: (map['fertilizeFrequencyDays'] as num?)?.toInt(),
        mistFrequencyDays: (map['mistFrequencyDays'] as num?)?.toInt(),
      ));
    }

    return plants;
  }

  Future<List<PhotoEntry>> _getPhotos(String plantId) async {
    final db = await database;
    final maps = await db.query(
      'photos',
      where: 'plantId = ?',
      whereArgs: [plantId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => PhotoEntry.fromJson(m)).toList();
  }

  Future<List<CareLog>> _getCareLogs(String plantId) async {
    final db = await database;
    final maps = await db.query(
      'care_logs',
      where: 'plantId = ?',
      whereArgs: [plantId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => CareLog.fromJson(m)).toList();
  }

  Future<List<Measurement>> _getMeasurements(String plantId) async {
    final db = await database;
    final maps = await db.query(
      'measurements',
      where: 'plantId = ?',
      whereArgs: [plantId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Measurement.fromJson(m)).toList();
  }

  Future<void> savePlant(Plant plant) async {
    final db = await database;
    await db.insert(
      'plants',
      {
        'id': plant.id,
        'name': plant.name,
        'species': plant.species,
        'roomId': plant.roomId,
        'acquiredDate': plant.acquiredDate.toIso8601String(),
        'notes': plant.notes,
        'isDead': plant.isDead ? 1 : 0,
        'isWishlist': plant.isWishlist ? 1 : 0,
        'createdAt': plant.createdAt.toIso8601String(),
        'waterFrequencyDays': plant.waterFrequencyDays,
        'fertilizeFrequencyDays': plant.fertilizeFrequencyDays,
        'mistFrequencyDays': plant.mistFrequencyDays,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.delete('photos', where: 'plantId = ?', whereArgs: [plant.id]);
    for (final photo in plant.photos) {
      await db.insert('photos', {
        'id': photo.id,
        'plantId': photo.plantId,
        'date': photo.date.toIso8601String(),
        'path': photo.path,
        'notes': photo.notes,
        'height': photo.height,
        'leafCount': photo.leafCount,
      });
    }

    await db.delete('care_logs', where: 'plantId = ?', whereArgs: [plant.id]);
    for (final log in plant.careLogs) {
      await db.insert('care_logs', {
        'id': log.id,
        'plantId': log.plantId,
        'type': log.type.name,
        'date': log.date.toIso8601String(),
        'notes': log.notes,
      });
    }

    await db.delete('measurements', where: 'plantId = ?', whereArgs: [plant.id]);
    for (final m in plant.measurements) {
      await db.insert('measurements', {
        'id': m.id,
        'plantId': m.plantId,
        'date': m.date.toIso8601String(),
        'height': m.height,
        'leafCount': m.leafCount,
        'stemWidth': m.stemWidth,
      });
    }
  }

  Future<void> deletePlant(String id) async {
    final db = await database;
    await db.delete('plants', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('photos');
    await db.delete('care_logs');
    await db.delete('measurements');
    await db.delete('plants');
    await db.delete('rooms');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
