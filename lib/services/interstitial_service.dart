import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ad_slot.dart';
import 'admob_service.dart';

/// Full-screen ads, shown only right after the user finishes something:
/// saving a scanned plant, leaving a fresh scan result, or saving a plant by
/// hand. Never on app open or exit, never while a scan is running.
///
/// Limits on top of Google's own rules: nothing until the user's third
/// completed task, then at most one ad every 5 minutes and 3 per session.
class InterstitialService {
  InterstitialService._();

  static const int minTasks = 3;
  static const Duration minGap = Duration(minutes: 5);
  static const int maxPerSession = 3;
  static const String _kTasks = 'interstitial_tasks';

  static InterstitialAd? _ad;
  static bool _loading = false;
  static DateTime? _lastShown;
  static int _shownThisSession = 0;
  static int _tasks = 0;
  static bool _tasksLoaded = false;

  /// Pure rule, kept separate so it can be unit tested.
  @visibleForTesting
  static bool allowed({
    required int tasks,
    required int shownThisSession,
    required DateTime? lastShown,
    required DateTime now,
  }) {
    if (tasks < minTasks) return false;
    if (shownThisSession >= maxPerSession) return false;
    if (lastShown != null && now.difference(lastShown) < minGap) return false;
    return true;
  }

  static Future<void> _loadTasks() async {
    if (_tasksLoaded) return;
    _tasksLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _tasks = prefs.getInt(_kTasks) ?? 0;
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
  /// immediately when nothing is shown.
  static Future<void> afterTask({bool count = true}) async {
    await _loadTasks();
    if (count) {
      _tasks++;
      await _saveTasks();
    }
    if (!AdMobService.isSupported || AdSlot.isPurchased) return;
    if (!allowed(
      tasks: _tasks,
      shownThisSession: _shownThisSession,
      lastShown: _lastShown,
      now: DateTime.now(),
    )) {
      return;
    }
    final ad = _ad;
    if (ad == null) {
      unawaited(preload());
      return;
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
    _shownThisSession++;
    try {
      await ad.show();
      await done.future;
    } catch (e) {
      debugPrint('Interstitial show error: $e');
    }
    unawaited(preload());
  }
}
