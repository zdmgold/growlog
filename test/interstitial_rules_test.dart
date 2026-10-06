import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/services/interstitial_service.dart';

void main() {
  final now = DateTime(2026, 10, 6, 12, 0);
  bool ok({int tasks = 3, int shown = 0, DateTime? last}) =>
      InterstitialService.allowed(
        tasks: tasks,
        shownThisSession: shown,
        lastShown: last,
        now: now,
      );

  test('nothing before the third completed task', () {
    expect(ok(tasks: 0), isFalse);
    expect(ok(tasks: 2), isFalse);
    expect(ok(tasks: 3), isTrue);
  });

  test('at most three per session', () {
    expect(ok(tasks: 10, shown: 2), isTrue);
    expect(ok(tasks: 10, shown: 3), isFalse);
  });

  test('at least five minutes between ads', () {
    expect(ok(last: now.subtract(const Duration(minutes: 4))), isFalse);
    expect(ok(last: now.subtract(const Duration(minutes: 5))), isTrue);
    expect(ok(last: now.subtract(const Duration(hours: 1))), isTrue);
  });
}
