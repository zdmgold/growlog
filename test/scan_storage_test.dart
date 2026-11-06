import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/models/scan_record.dart';
import 'package:growlog/services/local_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('an offline scan keeps its source and guesses through the database map',
      () {
    final r = ScanRecord(
      id: 'a',
      imagePath: '/x.jpg',
      createdAt: DateTime(2026, 11, 6),
      commonName: 'Swiss cheese plant',
      latinName: 'Monstera deliciosa',
      confidence: 'High',
      source: 'device',
      candidates: const ['Monstera deliciosa|0.91|0.31', 'Epipremnum aureum|0.05|0.2'],
    );
    final back = ScanRecord.fromMap(r.toMap());
    expect(back.isOnDevice, isTrue);
    expect(back.candidates, r.candidates);
    expect(back.copyWith(savedPlantId: 'p').source, 'device');
  });

  test('a cloud scan from before the upgrade still reads as a cloud scan', () {
    final old = ScanRecord.fromMap({
      'id': 'b',
      'imagePath': '/y.jpg',
      'createdAt': '2026-10-01T10:00:00.000',
      'commonName': 'Aloe',
      'health': 'watch',
    });
    expect(old.isOnDevice, isFalse);
    expect(old.candidates, isEmpty);
  });

  test('upgrading a version 2 database keeps its scans and adds the new columns',
      () async {
    final db = await openDatabase(inMemoryDatabasePath, version: 2,
        onCreate: (db, v) async {
      await db.execute('''CREATE TABLE scans(
        id TEXT PRIMARY KEY, plantId TEXT, imagePath TEXT NOT NULL,
        createdAt TEXT NOT NULL, isPlant INTEGER NOT NULL DEFAULT 1,
        commonName TEXT NOT NULL, latinName TEXT, confidence TEXT,
        health TEXT NOT NULL, issue TEXT, severity TEXT, summary TEXT,
        treatment TEXT, prevention TEXT, waterDays INTEGER,
        fertilizeDays INTEGER, light TEXT, savedPlantId TEXT)''');
      await db.insert('scans', {
        'id': 'old',
        'imagePath': '/old.jpg',
        'createdAt': '2026-10-01T10:00:00.000',
        'commonName': 'Aloe vera',
        'health': 'healthy',
      });
    });
    await LocalStorage.migrate(db, 2);
    final rows = await db.query('scans');
    expect(rows.length, 1);
    final rec = ScanRecord.fromMap(rows.first);
    expect(rec.commonName, 'Aloe vera');
    expect(rec.source, 'ai');
    // New offline scans can now be written and read back.
    await db.insert(
        'scans',
        ScanRecord(
          id: 'new',
          imagePath: '/n.jpg',
          createdAt: DateTime(2026, 11, 6),
          commonName: 'Ficus',
          source: 'device',
          candidates: const ['Ficus lyrata|0.9|0.3'],
        ).toMap());
    final all = (await db.query('scans')).map(ScanRecord.fromMap).toList();
    expect(all.where((r) => r.isOnDevice).length, 1);
    // Running the migration twice must not fail.
    await LocalStorage.migrate(db, 2);
    await db.close();
  });
}
