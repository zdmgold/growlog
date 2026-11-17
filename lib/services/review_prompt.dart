import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'interstitial_service.dart';

/// Asks for a store review with Google's own in-app popup, after the 10th
/// finished scan across at least 3 different days.
///
/// There is no "already rated" flag and no cooldown of our own: the store decides
/// whether the popup is actually shown. It is never requested in the same moment
/// as an interstitial ad, nor shortly after one.
class ReviewPrompt {
  static const int minScans = 10;
  static const int minDays = 3;

  /// How long after an interstitial the popup stays away.
  static const Duration afterAdGap = Duration(minutes: 2);

  static const String _kScans = 'review_scan_count';
  static const String _kDays = 'review_scan_days';
  static const int _maxDaysKept = 30;

  /// The rule, kept pure so a test covers it.
  @visibleForTesting
  static bool shouldAsk({
    required int scans,
    required int distinctDays,
    required bool adShownNow,
    required Duration? sinceLastAd,
  }) {
    if (scans < minScans || distinctDays < minDays) return false;
    if (adShownNow) return false;
    if (sinceLastAd != null && sinceLastAd < afterAdGap) return false;
    return true;
  }

  @visibleForTesting
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Counts one finished scan and remembers the day it happened.
  static Future<void> recordScan({DateTime? now}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kScans, (prefs.getInt(_kScans) ?? 0) + 1);
      final days = (prefs.getStringList(_kDays) ?? <String>[]).toList();
      final today = dayKey(now ?? DateTime.now());
      if (!days.contains(today)) {
        days.add(today);
        while (days.length > _maxDaysKept) {
          days.removeAt(0);
        }
        await prefs.setStringList(_kDays, days);
      }
    } catch (e) {
      debugPrint('ReviewPrompt.recordScan error: $e');
    }
  }

  /// Call at a calm moment after a finished scan, once the ad question for that
  /// moment is settled. [adShownNow] is the result of the interstitial call.
  static Future<void> maybeAsk({required bool adShownNow}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = InterstitialService.lastShownAt;
      final ask = shouldAsk(
        scans: prefs.getInt(_kScans) ?? 0,
        distinctDays: (prefs.getStringList(_kDays) ?? const <String>[]).length,
        adShownNow: adShownNow,
        sinceLastAd: last == null ? null : DateTime.now().difference(last),
      );
      if (!ask) return;
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        debugPrint('ReviewPrompt: requesting the in-app review');
        await review.requestReview();
      }
    } catch (e) {
      debugPrint('ReviewPrompt.maybeAsk error: $e');
    }
  }

  /// The Rate row in Settings opens the store listing.
  static Future<void> openStoreListing() async {
    try {
      await InAppReview.instance.openStoreListing();
    } catch (e) {
      debugPrint('ReviewPrompt.openStoreListing error: $e');
    }
  }
}
