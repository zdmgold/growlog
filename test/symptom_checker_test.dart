import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/services/offline/symptom_checker.dart';

void main() {
  final checker = SymptomChecker.parse(
      File('assets/care/symptoms.json').readAsStringSync());

  String top(Set<String> sel) => checker.rank(sel).first.problem.id;

  test('the knowledge base has every category and 40+ problems', () {
    expect(checker.problems.length, greaterThanOrEqualTo(40));
    final cats = checker.problems.map((p) => p.category).toSet();
    expect(cats, containsAll(
        ['water', 'light', 'temperature', 'nutrition', 'pot_soil', 'pests', 'disease', 'normal']));
  });

  test('every problem is complete and refers only to real options', () {
    final ids = {
      for (final g in checker.groups.values) for (final o in g) o.id,
    };
    for (final p in checker.problems) {
      expect(p.name.trim(), isNotEmpty, reason: p.id);
      expect(p.what.trim(), isNotEmpty, reason: p.id);
      expect(p.check.trim(), isNotEmpty, reason: p.id);
      expect(p.prevent.trim(), isNotEmpty, reason: p.id);
      expect(p.worry.trim(), isNotEmpty, reason: p.id);
      expect(p.steps.length, inInclusiveRange(2, 4), reason: p.id);
      expect(['low', 'med', 'high'], contains(p.severity), reason: p.id);
      for (final k in p.match.keys) {
        expect(ids, contains(k), reason: '${p.id} uses unknown option $k');
      }
    }
  });

  test('every symptom, pattern and condition counts towards some cause', () {
    final used = {for (final p in checker.problems) ...p.match.keys};
    for (final g in ['symptom', 'pattern', 'context']) {
      for (final o in checker.groups[g]!) {
        expect(used, contains(o.id), reason: '${o.id} matches nothing');
      }
    }
  });

  test('typical situations rank the right cause first', () {
    expect(top({'yellowing', 'wet_soil', 'no_drainage'}), 'overwatering');
    expect(top({'webbing', 'stippling', 'dry_air'}), 'spider_mites');
    expect(top({'white_fluff', 'sticky', 'insects'}), 'mealybugs');
    expect(top({'white_powder', 'humid_stagnant'}), 'powdery_mildew');
    expect(top({'tiny_flies', 'wet_soil'}), 'fungus_gnats');
    expect(top({'bleached', 'strong_sun'}), 'too_much_light');
    expect(top({'leggy', 'low_light'}), 'too_little_light');
    expect(top({'holes', 'insects'}), 'chewing_pests');
    expect(top({'leaf_drop', 'just_bought'}), 'settling_in');
    expect(top({'no_growth', 'winter', 'otherwise_healthy'}), 'dormancy');
  });

  test('nothing selected, or a weak match, gives no answer', () {
    expect(checker.rank({}), isEmpty);
    expect(checker.rank({'whole'}), isEmpty);
  });

  test('at most three causes, best first, with sensible confidence words', () {
    final r = checker.rank({'yellowing', 'wilting', 'leaf_drop', 'wet_soil'});
    expect(r.length, lessThanOrEqualTo(3));
    expect(r.first.confidence, Confidence.mostLikely);
    for (var i = 1; i < r.length; i++) {
      expect(r[i].score, lessThanOrEqualTo(r[i - 1].score));
      expect(r[i].confidence, isNot(Confidence.mostLikely));
    }
  });

  test('pests are never treated with anything stronger than soap or alcohol', () {
    final text = checker.problems
        .expand((p) => p.steps)
        .join(' ')
        .toLowerCase();
    for (final banned in ['pesticide', 'insecticide', 'bleach', 'fungicide']) {
      expect(text.contains(banned), isFalse, reason: banned);
    }
  });

  group('translated overlays', () {
    final base = File('assets/care/symptoms.json').readAsStringSync();
    final overlays = Directory('assets/care')
        .listSync()
        .whereType<File>()
        .where((f) => RegExp(r'symptoms_[a-z]+\.json$').hasMatch(f.path))
        .toList();

    test('every app language except English has a translation', () {
      final names = overlays.map((f) => f.path.split('/').last).toSet();
      expect(names, containsAll([
        for (final l in ['es', 'fr', 'de', 'pt', 'ar', 'hi', 'ja', 'ko', 'zh', 'he'])
          'symptoms_$l.json',
      ]));
    });

    for (final f in overlays) {
      final lang = f.path.split('/').last;
      test('$lang covers every label and problem and keeps step counts', () {
        final over = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        final english = SymptomChecker.parse(base);
        final tr = SymptomChecker.parse(base, overlay: f.readAsStringSync());
        final labels = over['labels'] as Map<String, dynamic>;
        for (final g in english.groups.values) {
          for (final o in g) {
            expect(labels[o.id], isA<String>(), reason: '$lang label ${o.id}');
            expect((labels[o.id] as String).trim(), isNotEmpty);
          }
        }
        for (var i = 0; i < english.problems.length; i++) {
          final e = english.problems[i];
          final t = tr.problems[i];
          expect(t.id, e.id);
          expect(t.steps.length, e.steps.length, reason: '$lang ${e.id}');
          // Translated, not silently falling back to English.
          // Some names are the same word in English and French (Thrips,
          // Anthracnose), so only the sentences are required to differ.
          expect(t.name.trim(), isNotEmpty, reason: '$lang ${e.id} name');
          expect(t.what, isNot(e.what), reason: '$lang ${e.id} what');
          expect(t.steps, isNot(e.steps), reason: '$lang ${e.id} steps');
          // Scoring data is never changed by translation.
          expect(t.match, e.match);
          expect(t.severity, e.severity);
        }
      });

      test('$lang gives the same ranking as English', () {
        final english = SymptomChecker.parse(base);
        final tr = SymptomChecker.parse(base, overlay: f.readAsStringSync());
        for (final sel in [
          {'yellowing', 'wet_soil', 'no_drainage'},
          {'webbing', 'stippling', 'dry_air'},
          {'white_powder', 'humid_stagnant'},
          {'wilting', 'dry_soil', 'hot_spot'},
          {'leaf_drop', 'just_moved'},
        ]) {
          expect(tr.rank(sel).map((d) => d.problem.id),
              english.rank(sel).map((d) => d.problem.id));
        }
      });
    }

    test('a missing or partial overlay falls back to English', () {
      final english = SymptomChecker.parse(base);
      final partial = SymptomChecker.parse(base,
          overlay: '{"labels":{"yellowing":"X"},"problems":{"rust":{"name":"Y","steps":["only one"]}}}');
      expect(partial.groups['symptom']!.first.label, 'X');
      final rust = partial.problems.firstWhere((p) => p.id == 'rust');
      final rustEn = english.problems.firstWhere((p) => p.id == 'rust');
      expect(rust.name, 'Y');
      expect(rust.steps, rustEn.steps); // wrong step count: whole list stays English
      expect(rust.what, rustEn.what);
    });
  });
}
