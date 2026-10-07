import 'dart:async';
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
      await _gatherConsent();
      // Google's rule: only start the SDK once the consent state allows ads.
      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
      }
    } catch (e) {
      debugPrint('AdMobService initialize error: $e');
    }
  }

  /// Refreshes the user's consent state and shows Google's consent message
  /// when one is required (for example in the EU or UK). The message itself
  /// is created in your AdMob account under Privacy & messaging.
  static Future<void> _gatherConsent() async {
    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!updated.isCompleted) updated.complete();
      },
      (FormError error) {
        debugPrint('Consent info update failed: ${error.errorCode} ${error.message}');
        if (!updated.isCompleted) updated.complete();
      },
    );
    await updated.future;

    final shown = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (error != null) {
        debugPrint('Consent form error: ${error.errorCode} ${error.message}');
      }
      if (!shown.isCompleted) shown.complete();
    });
    await shown.future;
  }

  /// True when the user must be able to reopen their privacy choices.
  static Future<bool> isPrivacyOptionsRequired() async {
    if (!isSupported) return false;
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('privacy options status error: $e');
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
