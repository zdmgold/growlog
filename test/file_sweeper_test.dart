import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/services/file_sweeper.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _u1 = '11111111-1111-4111-8111-111111111111';
const _u2 = '22222222-2222-4222-8222-222222222222';
const _u3 = '33333333-3333-4333-8333-333333333333';

File _make(Directory d, String name, {DateTime? modified, int bytes = 10}) {
  final f = File(p.join(d.path, name))..writeAsBytesSync(List.filled(bytes, 1));
  if (modified != null) f.setLastModifiedSync(modified);
  return f;
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final now = DateTime(2026, 11, 12, 12);
  final old = now.subtract(const Duration(days: 2));
  final fresh = now.subtract(const Duration(hours: 2));
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('sweep_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('orphan photos', () {
    test('only old, unreferenced photo files are chosen', () {
      final keep = _make(dir, 'plant_$_u1.jpg', modified: old);
      final orphanOld = _make(dir, 'plant_$_u2.jpg', modified: old);
      final orphanFresh = _make(dir, 'scan_$_u3.jpg', modified: fresh);
      final other = _make(dir, 'notes.txt', modified: old);
      final model = _make(dir, 'model.onnx', modified: old);
      final r = FileSweeper.orphanPhotos(
        files: [keep, orphanOld, orphanFresh, other, model],
        referencedNames: {'plant_$_u1.jpg'},
        now: now,
      );
      expect(r.map((f) => p.basename(f.path)), ['plant_$_u2.jpg']);
    });

    test('a file is matched by name, not by folder', () {
      final f = _make(dir, 'scan_$_u1.jpg', modified: old);
      expect(
        FileSweeper.orphanPhotos(
            files: [f], referencedNames: {'scan_$_u1.jpg'}, now: now),
        isEmpty,
      );
    });

    test('a zero minimum age lets tests sweep right away', () {
      final f = _make(dir, 'plant_$_u1.jpg', modified: fresh);
      expect(
        FileSweeper.orphanPhotos(
            files: [f], referencedNames: {}, now: now, minAge: Duration.zero),
        hasLength(1),
      );
    });

    test('database references include plant photos and scans', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('CREATE TABLE photos(id TEXT, path TEXT)');
      await db.execute('CREATE TABLE scans(id TEXT, imagePath TEXT)');
      await db.insert('photos', {'id': 'a', 'path': '/old/folder/plant_$_u1.jpg'});
      await db.insert('scans', {'id': 'b', 'imagePath': '/x/scan_$_u2.jpg'});
      expect(await FileSweeper.referencedNamesFrom(db),
          {'plant_$_u1.jpg', 'scan_$_u2.jpg'});
      await db.close();
    });

    test('clearAllPhotos removes every app photo and nothing else', () async {
      _make(dir, 'plant_$_u1.jpg');
      _make(dir, 'scan_$_u2.jpg');
      final keep = _make(dir, 'model.onnx');
      Directory(p.join(dir.path, 'sub')).createSync();
      _make(Directory(p.join(dir.path, 'sub')), 'plant_$_u3.jpg');
      final r = await FileSweeper.clearAllPhotos(dir: dir);
      expect(r.deleted, 2);
      expect(keep.existsSync(), isTrue);
      expect(File(p.join(dir.path, 'sub', 'plant_$_u3.jpg')).existsSync(), isTrue);
    });
  });

  group('temp files', () {
    test('old share and backup files go, young ones stay', () {
      final a = _make(dir, 'growlog_share_1.png', modified: old);
      final b = _make(dir, 'growlog_backup_2.json', modified: old);
      final c = _make(dir, 'growlog_share_3.png', modified: now);
      final d = _make(dir, 'something_else.png', modified: old);
      final r = FileSweeper.tempToDelete(files: [a, b, c, d], now: now);
      expect(r.map((f) => p.basename(f.path)).toSet(),
          {'growlog_share_1.png', 'growlog_backup_2.json'});
    });

    test('over the size cap the oldest young files go first', () {
      final a = _make(dir, 'growlog_share_1.png',
          modified: now.subtract(const Duration(minutes: 5)), bytes: 600);
      final b = _make(dir, 'growlog_share_2.png',
          modified: now.subtract(const Duration(minutes: 2)), bytes: 600);
      final r = FileSweeper.tempToDelete(files: [a, b], now: now, capBytes: 1000);
      expect(r.map((f) => p.basename(f.path)), ['growlog_share_1.png']);
    });
  });
}
