import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'local_storage.dart';

/// What a clean-up pass did.
class SweepReport {
  final int deleted;
  final int bytes;
  const SweepReport(this.deleted, this.bytes);
  static const none = SweepReport(0, 0);
  SweepReport operator +(SweepReport o) =>
      SweepReport(deleted + o.deleted, bytes + o.bytes);
}

/// Removes files the app no longer needs, and nothing else.
///
/// Safety rules, all enforced here:
/// - only files directly inside the folder given, never sub-folders;
/// - only names the app itself creates (plant_/scan_ photos, share and backup temp files);
/// - a photo is kept while any plant photo or saved scan refers to it, matched by file
///   name because the folder path can change between app updates on iPhone;
/// - a photo must also be older than a day, so Undo after deleting a plant still works;
/// - the offline model, the database and everything else are never touched.
class FileSweeper {
  static final RegExp photoName =
      RegExp(r'^(plant|scan)_[0-9a-fA-F-]{36}\.jpg$');
  static final RegExp tempName =
      RegExp(r'^growlog_(share_\d+\.png|backup_\d+\.json)$');

  static const Duration orphanAge = Duration(days: 1);
  static const Duration tempAge = Duration(minutes: 10);
  static const int tempCapBytes = 50 * 1024 * 1024;

  /// If nothing is referenced but this many photo files exist, something is wrong
  /// with the database read, so the sweep does nothing.
  static const int suspiciousCount = 20;

  // ---------- pure decisions (unit tested) ----------

  static List<File> orphanPhotos({
    required Iterable<File> files,
    required Set<String> referencedNames,
    required DateTime now,
    Duration minAge = orphanAge,
  }) {
    final candidates = <File>[];
    for (final f in files) {
      final name = p.basename(f.path);
      if (!photoName.hasMatch(name)) continue;
      if (referencedNames.contains(name)) continue;
      final age = now.difference(f.lastModifiedSync());
      if (age < minAge) continue;
      candidates.add(f);
    }
    return candidates;
  }

  /// Old temp files, then the oldest of the rest until the folder is under the cap.
  static List<File> tempToDelete({
    required Iterable<File> files,
    required DateTime now,
    Duration minAge = tempAge,
    int capBytes = tempCapBytes,
  }) {
    final mine = [
      for (final f in files)
        if (tempName.hasMatch(p.basename(f.path))) f,
    ];
    final doomed = <File>[];
    final keep = <File>[];
    for (final f in mine) {
      (now.difference(f.lastModifiedSync()) >= minAge ? doomed : keep).add(f);
    }
    keep.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
    var total = keep.fold<int>(0, (sum, f) => sum + f.lengthSync());
    var i = 0;
    while (total > capBytes && i < keep.length) {
      total -= keep[i].lengthSync();
      doomed.add(keep[i]);
      i++;
    }
    return doomed;
  }

  /// Names of every photo file the database refers to.
  static Future<Set<String>> referencedNamesFrom(Database db) async {
    final names = <String>{};
    for (final row in await db.rawQuery('SELECT path FROM photos')) {
      final v = row['path'] as String?;
      if (v != null && v.isNotEmpty) names.add(p.basename(v));
    }
    for (final row in await db.rawQuery('SELECT imagePath FROM scans')) {
      final v = row['imagePath'] as String?;
      if (v != null && v.isNotEmpty) names.add(p.basename(v));
    }
    return names;
  }

  // ---------- file work ----------

  static Iterable<File> _filesIn(Directory dir) {
    if (!dir.existsSync()) return const [];
    return dir
        .listSync(followLinks: false)
        .whereType<File>(); // sub-folders and links are ignored
  }

  static SweepReport _delete(Iterable<File> files) {
    var count = 0, bytes = 0;
    for (final f in files) {
      try {
        final size = f.lengthSync();
        f.deleteSync();
        count++;
        bytes += size;
      } catch (e) {
        debugPrint('FileSweeper could not delete ${p.basename(f.path)}: $e');
      }
    }
    return SweepReport(count, bytes);
  }

  /// Deletes photo files nothing refers to (older than [minAge]).
  static Future<SweepReport> sweepOrphanPhotos(
    LocalStorage storage, {
    Directory? dir,
    Duration minAge = orphanAge,
    bool dryRun = false,
    DateTime? now,
  }) async {
    try {
      final docs = dir ?? await getApplicationDocumentsDirectory();
      final referenced = referencedNamesFrom(await storage.database);
      final names = await referenced;
      final all = _filesIn(docs).where((f) => photoName.hasMatch(p.basename(f.path))).toList();
      if (names.isEmpty && all.length > suspiciousCount) {
        debugPrint('FileSweeper: nothing referenced but ${all.length} photos, skipping.');
        return SweepReport.none;
      }
      final orphans = orphanPhotos(
        files: all,
        referencedNames: names,
        now: now ?? DateTime.now(),
        minAge: minAge,
      );
      if (dryRun) {
        return SweepReport(orphans.length, orphans.fold(0, (s, f) => s + f.lengthSync()));
      }
      return _delete(orphans);
    } catch (e) {
      debugPrint('FileSweeper.sweepOrphanPhotos error: $e');
      return SweepReport.none;
    }
  }

  /// Deletes old share/backup temp files and trims the folder to the size cap.
  static Future<SweepReport> sweepTemp({
    Directory? dir,
    Duration minAge = tempAge,
    int capBytes = tempCapBytes,
    DateTime? now,
  }) async {
    try {
      final tmp = dir ?? await getTemporaryDirectory();
      return _delete(tempToDelete(
        files: _filesIn(tmp),
        now: now ?? DateTime.now(),
        minAge: minAge,
        capBytes: capBytes,
      ));
    } catch (e) {
      debugPrint('FileSweeper.sweepTemp error: $e');
      return SweepReport.none;
    }
  }

  /// Clear All Data: every photo file the app created, regardless of age.
  static Future<SweepReport> clearAllPhotos({Directory? dir}) async {
    try {
      final docs = dir ?? await getApplicationDocumentsDirectory();
      return _delete(
          _filesIn(docs).where((f) => photoName.hasMatch(p.basename(f.path))));
    } catch (e) {
      debugPrint('FileSweeper.clearAllPhotos error: $e');
      return SweepReport.none;
    }
  }

  /// One pass at app start. Never throws and never blocks the first screen.
  static Future<void> runAtStartup(LocalStorage storage) async {
    final a = await sweepOrphanPhotos(storage);
    final b = await sweepTemp();
    final t = a + b;
    if (t.deleted > 0) {
      debugPrint('FileSweeper removed ${t.deleted} files (${t.bytes} bytes).');
    }
  }

  /// Delete one temp file right after it was used. Quiet if it is already gone.
  static void deleteQuietly(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (e) {
      debugPrint('FileSweeper.deleteQuietly error: $e');
    }
  }
}
