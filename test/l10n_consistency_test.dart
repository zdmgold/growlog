import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> load(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> keys(Map<String, dynamic> m) =>
    m.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  const langs = ['es', 'fr', 'de', 'pt', 'ar', 'hi', 'ja', 'ko', 'zh', 'he'];
  final en = load('en');

  test('every language has exactly the same keys as English', () {
    for (final l in langs) {
      final other = keys(load(l));
      expect(keys(en).difference(other), isEmpty, reason: '$l is missing keys');
      expect(other.difference(keys(en)), isEmpty, reason: '$l has extra keys');
    }
  });

  test('every translation keeps the placeholders English uses', () {
    final ph = RegExp(r'\{(\w+)[,}]');
    for (final k in keys(en)) {
      final want = ph.allMatches(en[k] as String).map((m) => m.group(1)).toSet();
      for (final l in langs) {
        final text = load(l)[k] as String;
        final got = ph.allMatches(text).map((m) => m.group(1)).toSet();
        expect(got, want, reason: '$l / $k placeholders differ');
      }
    }
  });

  test('no translation is empty', () {
    for (final l in ['en', ...langs]) {
      final m = load(l);
      for (final k in keys(m)) {
        final v = m[k] as String;
        expect(v.trim().isNotEmpty, isTrue, reason: '$l / $k is empty');
      }
    }
  });
}
