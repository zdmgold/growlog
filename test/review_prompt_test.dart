import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/services/review_prompt.dart';

void main() {
  bool ask({
    int scans = 10,
    int days = 3,
    bool ad = false,
    Duration? since,
  }) =>
      ReviewPrompt.shouldAsk(
        scans: scans,
        distinctDays: days,
        adShownNow: ad,
        sinceLastAd: since,
      );

  test('needs the 10th finished scan and 3 different days', () {
    expect(ask(scans: 9), isFalse);
    expect(ask(days: 2), isFalse);
    expect(ask(scans: 10, days: 3), isTrue);
    expect(ask(scans: 40, days: 12), isTrue);
  });

  test('never in the same moment as an interstitial', () {
    expect(ask(ad: true), isFalse);
  });

  test('never shortly after an interstitial, fine once the gap has passed', () {
    expect(ask(since: const Duration(seconds: 30)), isFalse);
    expect(ask(since: const Duration(minutes: 1, seconds: 59)), isFalse);
    expect(ask(since: ReviewPrompt.afterAdGap), isTrue);
    expect(ask(since: const Duration(hours: 2)), isTrue);
    expect(ask(since: null), isTrue);
  });

  test('there is no cooldown or rated flag of our own', () {
    // The rule has no memory of earlier asks: the same inputs give the same answer.
    expect(ask(), isTrue);
    expect(ask(), isTrue);
  });

  test('days are kept as plain date keys', () {
    expect(ReviewPrompt.dayKey(DateTime(2026, 3, 7)), '2026-03-07');
    expect(ReviewPrompt.dayKey(DateTime(2026, 11, 17)), '2026-11-17');
  });
}
