import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google AdMob, using Google's official sample ad units.
///
/// The banner widget uses Google's official sample ad unit. It shows real Google test ads (labelled "Test Ad") and are safe
/// to tap. They earn nothing: swap in your own unit IDs from your AdMob account
/// before publishing. The app IDs in AndroidManifest.xml (Android) and
/// Info.plist (iOS) must be swapped too.
class AdMobService {
  AdMobService._();

  static Future<void>? _init;

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Google's sample units: fixed banner and interstitial, per platform.
  /// Replace with your own unit IDs from AdMob before publishing.
  static String? get bannerUnitId {
    if (!isSupported) return null;
    return Platform.isIOS
        ? 'ca-app-pub-3940256099942544/2934735716'
        : 'ca-app-pub-3940256099942544/6300978111';
  }

  static String? get interstitialUnitId {
    if (!isSupported) return null;
    return Platform.isIOS
        ? 'ca-app-pub-3940256099942544/4411468910'
        : 'ca-app-pub-3940256099942544/1033173712';
  }

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
