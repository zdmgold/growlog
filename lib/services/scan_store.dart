import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/scan_record.dart';
import 'local_storage.dart';

/// Saved scans, newest first. Backed by the local database.
class ScanStore extends ChangeNotifier {
  ScanStore._();
  static final ScanStore instance = ScanStore._();

  final LocalStorage _storage = LocalStorage();
  List<ScanRecord> _scans = const [];

  List<ScanRecord> get scans => _scans;

  Future<void> load() async {
    try {
      _scans = await _storage.getScans();
    } catch (e) {
      debugPrint('ScanStore.load error: $e');
    }
    notifyListeners();
  }

  Future<void> add(ScanRecord record) async {
    try {
      await _storage.saveScan(record);
      _scans = await _storage.getScans();
    } catch (e) {
      debugPrint('ScanStore.add error: $e');
    }
    notifyListeners();
  }

  Future<void> markSaved(String scanId, String plantId) async {
    try {
      await _storage.markScanSaved(scanId, plantId);
      _scans = await _storage.getScans();
    } catch (e) {
      debugPrint('ScanStore.markSaved error: $e');
    }
    notifyListeners();
  }

  Future<void> delete(ScanRecord record) async {
    try {
      await _storage.deleteScan(record.id);
      _scans = await _storage.getScans();
      final file = File(record.imagePath);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('ScanStore.delete error: $e');
    }
    notifyListeners();
  }
}
