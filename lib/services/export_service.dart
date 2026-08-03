import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import '../models/plant_model.dart';

class ExportService {
  static Future<Uint8List?> captureWidget(RenderRepaintBoundary boundary) async {
    try {
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('ExportService.captureWidget error: $e');
      return null;
    }
  }

  static Future<void> shareImage(Uint8List imageBytes, {String? text}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/growlog_share_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text ?? 'My plant growth with GrowLog',
      );
    } catch (e) {
      debugPrint('ExportService.shareImage error: $e');
    }
  }

  static Future<void> sharePlantPhotos(Plant plant) async {
    try {
      final files = <XFile>[];
      for (final photo in plant.photos) {
        if (File(photo.path).existsSync()) {
          files.add(XFile(photo.path));
        }
      }
      if (files.isNotEmpty) {
        await Share.shareXFiles(
          files,
          text: '${plant.name} growth journey — tracked with GrowLog',
        );
      }
    } catch (e) {
      debugPrint('ExportService.sharePlantPhotos error: $e');
    }
  }

  static Future<String> exportToJson(List<Plant> plants, List<Room> rooms) async {
    try {
      final data = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'plants': plants.map((p) => p.toJson()).toList(),
        'rooms': rooms.map((r) => r.toJson()).toList(),
      };
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/growlog_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonEncode(data));
      return file.path;
    } catch (e) {
      debugPrint('ExportService.exportToJson error: $e');
      throw Exception('Failed to export backup');
    }
  }

  static Future<Map<String, dynamic>?> readBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ExportService.readBackupFile error: $e');
      return null;
    }
  }

  static Future<void> shareBackupFile(String filePath) async {
    try {
      if (File(filePath).existsSync()) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'GrowLog backup',
        );
      }
    } catch (e) {
      debugPrint('ExportService.shareBackupFile error: $e');
    }
  }
}
