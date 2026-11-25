import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/l10n/app_localizations.dart';

/// Runs the generated plural messages (the real Flutter/intl selection, not a copy of the ARB text).
/// Dart's rules (intl plural_rules.dart): Arabic 0 zero, 1 one, 2 two, n%100 in 3..10 few, 11..99 many, else
/// other (100, 101, 102 ...). Hebrew: 1 one, 2 two, else other.
const _langs = ['en', 'es', 'fr', 'de', 'pt', 'ar', 'hi', 'ja', 'ko', 'zh', 'he'];

Future<AppLocalizations> _load(String code) => AppLocalizations.delegate.load(Locale(code));

void main() {
  group('Arabic plural forms', () {
    late AppLocalizations ar;
    setUpAll(() async => ar = await _load('ar'));

    test('days ago: one, two, few, many, other', () {
      expect(ar.daysAgo(1), 'قبل يوم واحد');
      expect(ar.daysAgo(2), 'قبل يومين');
      expect(ar.daysAgo(3), 'قبل 3 أيام');
      expect(ar.daysAgo(10), 'قبل 10 أيام');
      expect(ar.daysAgo(11), 'قبل 11 يومًا');
      expect(ar.daysAgo(15), 'قبل 15 يومًا');
      expect(ar.daysAgo(99), 'قبل 99 يومًا');
      expect(ar.daysAgo(100), 'قبل 100 يوم');
      expect(ar.daysAgo(102), 'قبل 102 يوم');
      expect(ar.daysAgo(103), 'قبل 103 أيام');
      expect(ar.daysAgo(111), 'قبل 111 يومًا');
    });

    test('plants that need care today', () {
      expect(ar.statusDue(1), 'نبتة واحدة تحتاج إلى عناية اليوم');
      expect(ar.statusDue(2), 'نبتتان تحتاجان إلى عناية اليوم');
      expect(ar.statusDue(5), '5 نباتات تحتاج إلى عناية اليوم');
      expect(ar.statusDue(12), '12 نباتًا تحتاج إلى عناية اليوم');
      expect(ar.statusDue(100), '100 نبات تحتاج إلى عناية اليوم');
    });

    test('every N days, overdue days, plant and photo counts', () {
      expect(ar.everyNDays(1), 'كل يوم');
      expect(ar.everyNDays(2), 'كل يومين');
      expect(ar.everyNDays(7), 'كل 7 أيام');
      expect(ar.everyNDays(14), 'كل 14 يومًا');
      expect(ar.everyNDays(30), 'كل 30 يومًا');
      expect(ar.overdueDays(2), 'متأخر يومين');
      expect(ar.overdueDays(5), 'متأخر 5 أيام');
      expect(ar.overdueDays(15), 'متأخر 15 يومًا');
      expect(ar.plantCountLabel(2), 'نبتتان');
      expect(ar.plantCountLabel(3), '3 نباتات');
      expect(ar.photosCount(1), 'صورة واحدة');
      expect(ar.photosCount(2), 'صورتان');
      expect(ar.photosCount(3), '3 صور');
      expect(ar.photosCount(11), '11 صورة');
    });

    test('photos over a span (plural on the days placeholder)', () {
      expect(ar.photosSpan(5, 40), 'الصور: 5، على مدى 40 يومًا');
      expect(ar.photosSpan(3, 2), 'الصور: 3، على مدى يومين');
      expect(ar.photosSpan(4, 7), 'الصور: 4، على مدى 7 أيام');
    });

    test('room card label', () {
      expect(ar.roomCardAccessibility(3, 'غرفة'), 'غرفة، 3 نباتات');
      expect(ar.roomCardAccessibility(2, 'غرفة'), 'غرفة، نبتتان');
    });
  });

  group('Hebrew plural forms', () {
    late AppLocalizations he;
    setUpAll(() async => he = await _load('he'));

    test('dual forms and the rest', () {
      expect(he.statusDue(1), 'צמח אחד זקוק לטיפול היום');
      expect(he.statusDue(2), 'שני צמחים זקוקים לטיפול היום');
      expect(he.statusDue(5), '5 צמחים זקוקים לטיפול היום');
      expect(he.overdueDays(1), 'באיחור של יום אחד');
      expect(he.overdueDays(2), 'באיחור של יומיים');
      expect(he.overdueDays(3), 'באיחור של 3 ימים');
      expect(he.everyNDays(1), 'כל יום');
      expect(he.everyNDays(2), 'כל יומיים');
      expect(he.everyNDays(7), 'כל 7 ימים');
      expect(he.plantCountLabel(2), 'שני צמחים');
      expect(he.photosCount(1), 'תמונה אחת');
      expect(he.photosCount(2), 'שתי תמונות');
      expect(he.photosCount(3), '3 תמונות');
    });

    test('photos over a span', () {
      expect(he.photosSpan(5, 2), 'תמונות: 5, במשך יומיים');
      expect(he.photosSpan(5, 40), 'תמונות: 5, במשך 40 ימים');
      expect(he.photosSpan(5, 1), 'תמונות: 5, במשך יום אחד');
    });
  });

  group('every plural message, every language, many counts', () {
    const counts = [0, 1, 2, 3, 4, 5, 10, 11, 12, 21, 22, 100, 101, 102, 103, 111, 999];
    final messages = <String, String Function(AppLocalizations, int)>{
      'daysAgo': (l, c) => l.daysAgo(c),
      'weeksAgo': (l, c) => l.weeksAgo(c),
      'monthsAgo': (l, c) => l.monthsAgo(c),
      'yearsAgo': (l, c) => l.yearsAgo(c),
      'careDueInDays': (l, c) => l.careDueInDays(c),
      'statusDue': (l, c) => l.statusDue(c),
      'overdueDays': (l, c) => l.overdueDays(c),
      'everyNDays': (l, c) => l.everyNDays(c),
      'plantCountLabel': (l, c) => l.plantCountLabel(c),
      'photosCount': (l, c) => l.photosCount(c),
      'photosSpan': (l, c) => l.photosSpan(c, c + 1),
      'roomCardAccessibility': (l, c) => l.roomCardAccessibility(c, 'Room'),
    };

    for (final lang in _langs) {
      test('$lang: no empty text, no leftover ICU syntax, the count is present from 3 up', () async {
        final l = await _load(lang);
        for (final entry in messages.entries) {
          for (final c in counts) {
            final s = entry.value(l, c);
            final where = '$lang ${entry.key}($c) -> "$s"';
            expect(s.trim().isNotEmpty, true, reason: where);
            expect(s.contains('{') || s.contains('}') || s.contains('plural'), false, reason: where);
            if (c >= 3) expect(s.contains('$c'), true, reason: where);
          }
        }
      });
    }
  });
}
