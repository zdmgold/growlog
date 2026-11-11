import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/services/interstitial_service.dart';

void main() {
  final now = DateTime(2026, 10, 6, 12, 0);
  bool ok({int tasks = 5, DateTime? last}) => InterstitialService.allowed(
        tasks: tasks,
        lastShown: last,
        now: now,
      );

  test('nothing before the fifth completed task', () {
    expect(ok(tasks: 0), isFalse);
    expect(ok(tasks: 4), isFalse);
    expect(ok(tasks: 5), isTrue);
  });

  test('at least seven minutes between ads', () {
    expect(ok(last: now.subtract(const Duration(minutes: 6))), isFalse);
    expect(ok(last: now.subtract(const Duration(minutes: 7))), isTrue);
    expect(ok(last: now.subtract(const Duration(hours: 1))), isTrue);
  });

  test('no cap per session or per day', () {
    // Many tasks and many earlier ads never block a later one on their own.
    expect(ok(tasks: 500, last: now.subtract(const Duration(minutes: 8))), isTrue);
  });
}
