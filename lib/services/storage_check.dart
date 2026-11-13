import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/foundation.dart';

/// Free-space check before a big download, so it fails early and clearly
/// instead of halfway.
class StorageCheck {
  /// Room left over after the download, for the database, photos and the system.
  static const int marginBytes = 150 * 1000 * 1000;

  /// The plugin reports megabytes. If it cannot tell, do not block the person.
  static bool enough({required int needBytes, required double? freeMb}) {
    if (freeMb == null) return true;
    return freeMb * 1024 * 1024 >= needBytes + marginBytes;
  }

  static Future<double?> freeMb() async {
    try {
      final mb = await DiskSpacePlus().getFreeDiskSpace;
      debugPrint('StorageCheck free space: $mb MB');
      return mb;
    } catch (e) {
      debugPrint('StorageCheck.freeMb error: $e');
      return null;
    }
  }
}
