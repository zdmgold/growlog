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
}
