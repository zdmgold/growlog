import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google AdMob, using Google's official sample ad units.
///
/// The banner widget uses Google's official sample ad unit. It shows real Google test ads (labelled "Test Ad") and are safe
/// to tap. They earn nothing: swap in your own unit ID from your AdMob account
/// before publishing. The app ID in AndroidManifest.xml must be swapped too.
class AdMobService {
  AdMobService._();

  static Future<void>? _init;

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Starts the Mobile Ads SDK once. Safe to call repeatedly.
  static Future<void> initialize() => ready;

  static Future<void> get ready {
    return _init ??= _start();
  }

  static Future<void> _start() async {
    if (!isSupported) return;
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('AdMobService initialize error: $e');
    }
  }
}
