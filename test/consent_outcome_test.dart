import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/services/admob_service.dart';

void main() {
  ConsentDecision run({
    required bool failed,
    required bool? can,
    bool options = false,
  }) =>
      AdMobService.consentOutcome(
        failed: failed,
        canRequestAds: can,
        privacyOptionsRequired: options,
      );

  test('an error always allows ads to be requested', () {
    expect(run(failed: true, can: null).requestAds, isTrue);
    expect(run(failed: true, can: false).requestAds, isTrue);
    expect(run(failed: true, can: true).requestAds, isTrue);
  });

  test('without an error, Google\'s own answer is used', () {
    expect(run(failed: false, can: true).requestAds, isTrue);
    expect(run(failed: false, can: false).requestAds, isFalse);
  });

  test('the privacy choices flag is kept as read, with or without an error', () {
    expect(run(failed: false, can: true, options: true).privacyOptionsRequired,
        isTrue);
    expect(run(failed: true, can: null, options: true).privacyOptionsRequired,
        isTrue);
    expect(run(failed: false, can: true, options: false).privacyOptionsRequired,
        isFalse);
  });
}
