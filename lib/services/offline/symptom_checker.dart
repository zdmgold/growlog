import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One tappable answer in the guided check (a symptom, a pattern, a condition).
class SymptomOption {
  final String id;
  final String label;
  const SymptomOption(this.id, this.label);
}

/// One problem the checker can name, with conservative first steps.
class Problem {
  final String id;
  final String name;
  final String category;
  final String severity; // low, med, high
  final String what;
  final String check;
  final List<String> steps;
  final String prevent;
  final String worry;
  final Map<String, int> match;

  const Problem({
    required this.id,
    required this.name,
    required this.category,
    required this.severity,
    required this.what,
    required this.check,
    required this.steps,
    required this.prevent,
    required this.worry,
    required this.match,
  });

  factory Problem.fromJson(Map<String, dynamic> j) => Problem(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['cat'] as String,
        severity: j['sev'] as String,
        what: j['what'] as String,
        check: j['check'] as String,
        steps: [for (final s in j['steps'] as List) s as String],
        prevent: j['prevent'] as String,
        worry: j['worry'] as String,
        match: {
          for (final e in (j['match'] as Map<String, dynamic>).entries)
            e.key: (e.value as num).toInt(),
        },
      );
}

enum Confidence { mostLikely, possible, lessLikely }

class Diagnosis {
  final Problem problem;
  final int score;
  final Confidence confidence;
  const Diagnosis(this.problem, this.score, this.confidence);
}

/// Offline Doctor: ranks likely causes from what the person selects. It is a
/// guided check, not a guess from a photo, and works with no key or internet.
class SymptomChecker {
  SymptomChecker._(this.groups, this.problems);

  /// Option groups in step order: part, symptom, pattern, context.
  final Map<String, List<SymptomOption>> groups;
  final List<Problem> problems;

  /// A cause needs at least this much matching evidence to be shown.
  static const int minScore = 3;
  static const int maxResults = 3;

  static SymptomChecker? _instance;

  static Future<SymptomChecker> load() async {
    final cached = _instance;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/care/symptoms.json');
    return _instance = parse(raw);
  }

  @visibleForTesting
  static SymptomChecker parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final g = <String, List<SymptomOption>>{};
    for (final e in (j['groups'] as Map<String, dynamic>).entries) {
      g[e.key] = [
        for (final o in e.value as List)
          SymptomOption(
            (o as Map<String, dynamic>)['id'] as String,
            o['label'] as String,
          ),
      ];
    }
    return SymptomChecker._(g, [
      for (final p in j['problems'] as List)
        Problem.fromJson(p as Map<String, dynamic>),
    ]);
  }

  static int _sev(String s) => s == 'high' ? 2 : (s == 'med' ? 1 : 0);

  /// Top causes for the selected option ids. Empty when nothing matches
  /// strongly enough, so the app says so instead of guessing.
  List<Diagnosis> rank(Set<String> selected) {
    final scored = <MapEntry<Problem, int>>[];
    for (final p in problems) {
      var score = 0;
      for (final id in selected) {
        score += p.match[id] ?? 0;
      }
      if (score >= minScore) scored.add(MapEntry(p, score));
    }
    if (scored.isEmpty) return const [];
    scored.sort((a, b) {
      final c = b.value.compareTo(a.value);
      if (c != 0) return c;
      final s = _sev(b.key.severity).compareTo(_sev(a.key.severity));
      return s != 0 ? s : a.key.name.compareTo(b.key.name);
    });
    final top = scored.first.value;
    final out = <Diagnosis>[];
    for (final e in scored) {
      if (out.length >= maxResults) break;
      if (e.value * 2 < top) break; // far weaker than the best match
      final Confidence c;
      if (out.isEmpty) {
        c = Confidence.mostLikely;
      } else if (e.value * 4 >= top * 3) {
        c = Confidence.possible;
      } else {
        c = Confidence.lessLikely;
      }
      out.add(Diagnosis(e.key, e.value, c));
    }
    return out;
  }
}
