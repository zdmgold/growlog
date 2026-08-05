import 'package:flutter/material.dart';

/// AdMob service with graceful degradation.
/// If google_mobile_ads is unavailable or fails, all methods safely no-op
/// and the banner widget renders as zero-height (invisible).
///
/// VERIFIED GENUINE STUB — bannerAd() always returns SizedBox.shrink().
/// Confirmed this is not wired to any screen anywhere in the app either,
/// so the "ads fund the free app" plan currently generates $0 real
/// revenue until this is actually implemented AND placed in the UI.
class AdMobService {
  static bool _initialized = false;
  static bool _available = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      // Attempt to initialize AdMob if the plugin is present.
      // If google_mobile_ads is removed from pubspec, this silently fails.
      _available = true;
      _initialized = true;
      debugPrint('AdMob initialized');
    } catch (e) {
      _available = false;
      _initialized = true;
      debugPrint('AdMob unavailable: $e');
    }
  }

  static bool get isAvailable => _available;

  static String get bannerAdUnitId {
    // Use test IDs during development. Replace with production IDs before release.
    // iOS test banner: ca-app-pub-3940256099942544/2934735716
    // Android test banner: ca-app-pub-3940256099942544/6300978111
    return '';
  }

  static Widget bannerAd() {
    if (!_available) return const SizedBox.shrink();
    // If google_mobile_ads is integrated, replace this with:
    // return BannerAdWidget(adUnitId: bannerAdUnitId);
    // For now, return zero-height to keep builds passing.
    return const SizedBox.shrink();
  }

  static void dispose() {}
}
