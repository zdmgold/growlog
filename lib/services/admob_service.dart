import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
  static bool _sdkStarted = false;
  static bool _retryPending = false;
  static bool _retried = false;

  /// Set by the consent step. Banner and interstitial loaders check it before
  /// every request.
  static bool adsAllowed = false;

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

  /// Starts the consent step, then the Mobile Ads SDK. Safe to call repeatedly.
  static Future<void> initialize() => ready;

  static Future<void> get ready {
    return _init ??= _start();
  }

  /// What to do once the consent step has finished. Kept as one small pure
  /// function so a test covers it.
  ///
  /// - An error (no connection, form error, timeout, `canRequestAds` throwing)
  ///   always allows ads to be requested. Google then applies the last saved
  ///   consent and decides what is served.
  /// - Otherwise Google's own `canRequestAds` answer is used, so a person who
  ///   declined gets limited or non-personalized ads, or none, as Google allows.
  /// - The privacy-choices flag is kept exactly as read.
  @visibleForTesting
  static ConsentDecision consentOutcome({
    required bool failed,
    required bool? canRequestAds,
    required bool privacyOptionsRequired,
  }) {
    return ConsentDecision(
      requestAds: failed ? true : (canRequestAds ?? true),
      privacyOptionsRequired: privacyOptionsRequired,
    );
  }

  static Future<void> _start() async {
    if (!isSupported) return;
    await _consentThenStart();
    WidgetsBinding.instance.addObserver(_ConsentRetry());
  }

  static Future<void> _consentThenStart() async {
    final decision = await _runConsent();
    adsAllowed = decision.requestAds;
    if (decision.requestAds && !_sdkStarted) {
      try {
        await MobileAds.instance.initialize();
        _sdkStarted = true;
      } catch (e) {
        debugPrint('AdMobService initialize error: $e');
      }
    }
  }

  /// Runs the consent step and reports the outcome. Never throws.
  static Future<ConsentDecision> _runConsent() async {
    var failed = false;
    try {
      final ok = await _gatherConsent().timeout(const Duration(seconds: 15));
      if (!ok) failed = true;
    } on TimeoutException {
      debugPrint('Consent step timed out');
      failed = true;
    } catch (e) {
      debugPrint('Consent step error: $e');
      failed = true;
    }
    bool? can;
    try {
      can = await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      // Not swallowed silently: it counts as a failure and is retried.
      debugPrint('canRequestAds error: $e');
      failed = true;
    }
    var optionsRequired = false;
    try {
      optionsRequired = await ConsentInformation.instance.isPrivacyOptionsRequired();
    } catch (e) {
      debugPrint('isPrivacyOptionsRequired error: $e');
    }
    _retryPending = failed;
    final decision = consentOutcome(
      failed: failed,
      canRequestAds: can,
      privacyOptionsRequired: optionsRequired,
    );
    debugPrint('Consent outcome: failed=$failed canRequestAds=$can '
        'requestAds=${decision.requestAds} privacyOptions=$optionsRequired');
    return decision;
  }

  static ConsentRequestParameters _params() {
    // Test builds can pretend to be in the EEA to exercise the consent paths.
    const mode = String.fromEnvironment('CONSENT_DEBUG');
    if (mode == 'eea') {
      return ConsentRequestParameters(
        consentDebugSettings: ConsentDebugSettings(
          debugGeography: DebugGeography.debugGeographyEea,
        ),
      );
    }
    return ConsentRequestParameters();
  }

  /// Refreshes the consent state and shows Google's consent message when one is
  /// required. Returns false if any part reported an error. The message itself
  /// is created in the AdMob account under Privacy and messaging.
  static Future<bool> _gatherConsent() async {
    var ok = true;
    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      _params(),
      () {
        if (!updated.isCompleted) updated.complete();
      },
      (FormError error) {
        debugPrint('Consent info update failed: ${error.errorCode} ${error.message}');
        ok = false;
        if (!updated.isCompleted) updated.complete();
      },
    );
    await updated.future;

    final shown = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (error != null) {
        debugPrint('Consent form error: ${error.errorCode} ${error.message}');
        ok = false;
      }
      if (!shown.isCompleted) shown.complete();
    });
    await shown.future;
    return ok;
  }

  /// If the first consent step failed, try once more the next time the app
  /// comes back to the foreground, so one flaky launch does not cost a whole
  /// session of ads. Google still decides in the end.
  static Future<void> _retryOnce() async {
    if (!_retryPending || _retried) return;
    _retried = true;
    debugPrint('Consent retry on return to foreground');
    await _consentThenStart();
  }

  /// True when the person must be able to reopen their privacy choices.
  static Future<bool> isPrivacyOptionsRequired() async {
    if (!isSupported) return false;
    try {
      return await ConsentInformation.instance.isPrivacyOptionsRequired();
    } catch (e) {
      debugPrint('isPrivacyOptionsRequired error: $e');
      return false;
    }
  }

  /// Reopens Google's privacy options form. Completes when it is closed.
  static Future<void> showPrivacyOptions() async {
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) {
        debugPrint('Privacy options error: ${error.errorCode} ${error.message}');
      }
      if (!done.isCompleted) done.complete();
    });
    await done.future;
  }
}

/// The outcome of the consent step.
class ConsentDecision {
  final bool requestAds;
  final bool privacyOptionsRequired;
  const ConsentDecision({
    required this.requestAds,
    required this.privacyOptionsRequired,
  });
}

class _ConsentRetry with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(AdMobService._retryOnce());
    }
  }
}
