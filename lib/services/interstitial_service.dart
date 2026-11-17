import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ad_slot.dart';
import 'admob_service.dart';

/// Full-screen ads, shown only right after the user finishes something:
/// saving a scanned plant, leaving a fresh scan result, saving a plant by
/// hand, leaving the symptom check results, or adding a photo update. Never on
/// app open or exit, never on the camera, never while a scan is running.
///
/// Limits on top of Google's own rules: nothing until the user's fifth
/// completed task, then at most one ad every 7 minutes, counted from the last
/// ad even across an app restart. There is no cap per session and no cap per day.
class InterstitialService {
  InterstitialService._();

  static const int minTasks = 5;
  static const Duration minGap = Duration(minutes: 7);
  static const String _kTasks = 'interstitial_tasks';
  static const String _kLastShown = 'interstitial_last_shown';

  static InterstitialAd? _ad;
  static bool _loading = false;
  static DateTime? _lastShown;
  static int _tasks = 0;
  static bool _tasksLoaded = false;

  /// Pure rule, kept separate so it can be unit tested.
  @visibleForTesting
  static bool allowed({
    required int tasks,
    required DateTime? lastShown,
    required DateTime now,
  }) {
    if (tasks < minTasks) return false;
    if (lastShown != null && now.difference(lastShown) < minGap) return false;
    return true;
  }

  /// Turns the saved time back into a date. A missing value, or one in the
  /// future (the phone's clock was set back), is ignored so it can never block
  /// ads for longer than the gap.
  @visibleForTesting
  static DateTime? decodeLastShown(int? millis, {required DateTime now}) {
    if (millis == null) return null;
    final t = DateTime.fromMillisecondsSinceEpoch(millis);
    return t.isAfter(now) ? null : t;
  }

  static Future<void> _saveLastShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final t = _lastShown;
      if (t != null) await prefs.setInt(_kLastShown, t.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('InterstitialService last-shown save error: $e');
    }
  }

  static Future<void> _loadTasks() async {
    if (_tasksLoaded) return;
    _tasksLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _tasks = prefs.getInt(_kTasks) ?? 0;
      // The gap between ads survives a restart.
      _lastShown ??= decodeLastShown(prefs.getInt(_kLastShown), now: DateTime.now());
    } catch (e) {
      debugPrint('InterstitialService tasks load error: $e');
    }
  }

  static Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kTasks, _tasks);
    } catch (e) {
      debugPrint('InterstitialService tasks save error: $e');
    }
  }

  /// Loads the next ad in the background so it is ready when needed.
  static Future<void> preload() async {
    if (!AdMobService.isSupported || AdSlot.isPurchased) return;
    if (_ad != null || _loading) return;
    _loading = true;
    await AdMobService.ready;
    if (!AdMobService.adsAllowed) {
      _loading = false;
      return;
    }
    await InterstitialAd.load(
      adUnitId: AdMobService.interstitialUnitId!,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: ${error.code} ${error.message}');
          _ad = null;
          _loading = false;
        },
      ),
    );
  }

  /// Call at a finish point. Counts the task (unless [count] is false), and
  /// shows an ad if every rule allows it. Completes when the ad is closed, or
  /// immediately when nothing is shown. Returns true when an ad was shown.
  static Future<bool> afterTask({bool count = true}) async {
    await _loadTasks();
    if (count) {
      _tasks++;
      await _saveTasks();
    }
    if (!AdMobService.isSupported || AdSlot.isPurchased) return false;
    if (!allowed(
      tasks: _tasks,
      lastShown: _lastShown,
      now: DateTime.now(),
    )) {
      return false;
    }
    final ad = _ad;
    if (ad == null) {
      unawaited(preload());
      return false;
    }
    _ad = null;

    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        debugPrint('Interstitial failed to show: ${error.code} ${error.message}');
        a.dispose();
        if (!done.isCompleted) done.complete();
      },
    );
    _lastShown = DateTime.now();
    unawaited(_saveLastShown());
    try {
      await ad.show();
      await done.future;
    } catch (e) {
      debugPrint('Interstitial show error: $e');
    }
    unawaited(preload());
    return true;
  }

  /// When the last interstitial was shown, or null if none this install.
  static DateTime? get lastShownAt => _lastShown;
}
