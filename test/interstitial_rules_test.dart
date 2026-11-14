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

  group('the gap survives a restart', () {
    test('a saved time is read back as the last ad', () {
      final shown = now.subtract(const Duration(minutes: 3));
      final read = InterstitialService.decodeLastShown(
          shown.millisecondsSinceEpoch,
          now: now);
      expect(read, shown);
      // Three minutes after an ad, another is still not allowed.
      expect(ok(last: read), isFalse);
    });

    test('nothing saved means no earlier ad', () {
      expect(InterstitialService.decodeLastShown(null, now: now), isNull);
    });

    test('a time in the future (clock set back) is ignored', () {
      final future = now.add(const Duration(days: 3));
      expect(
        InterstitialService.decodeLastShown(future.millisecondsSinceEpoch,
            now: now),
        isNull,
      );
    });
  });
}
