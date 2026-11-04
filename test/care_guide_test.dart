import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/services/offline/care_guide.dart';

void main() {
  final entries = CareGuide.parse(
      File('assets/care/care_guide.json').readAsStringSync());

  test('the care guide covers every species the offline model knows', () {
    expect(entries.length, 107);
  });

  test('every entry has a name and sensible intervals', () {
    for (final e in entries.values) {
      expect(e.common.trim().isNotEmpty, isTrue, reason: e.species);
      expect(e.waterDays, inInclusiveRange(2, 60), reason: e.species);
      if (e.feedDays != null) {
        expect(e.feedDays!, inInclusiveRange(7, 120), reason: e.species);
      }
    }
  });

  test('desert plants are watered less often than ferns', () {
    expect(entries['Opuntia microdasys']!.waterDays,
        greaterThan(entries['Nephrolepis exaltata']!.waterDays));
  });

  test('lithops are not fed on a schedule', () {
    expect(entries['Lithops']!.feedDays, isNull);
  });
}
