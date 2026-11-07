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

  static final Map<String, SymptomChecker> _cache = {};

  /// Loads the knowledge base in [lang]. English is the base. Another language
  /// is an overlay file (assets/care/symptoms_<lang>.json) and any field it
  /// does not translate falls back to English.
  static Future<SymptomChecker> load({String lang = 'en'}) async {
    final cached = _cache[lang];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/care/symptoms.json');
    String? overlay;
    if (lang != 'en') {
      try {
        overlay = await rootBundle.loadString('assets/care/symptoms_$lang.json');
      } catch (_) {
        overlay = null; // language not translated yet
      }
    }
    return _cache[lang] = parse(raw, overlay: overlay);
  }

  @visibleForTesting
  static SymptomChecker parse(String raw, {String? overlay}) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final o = overlay == null
        ? const <String, dynamic>{}
        : jsonDecode(overlay) as Map<String, dynamic>;
    final labels = (o['labels'] as Map<String, dynamic>?) ?? const {};
    final texts = (o['problems'] as Map<String, dynamic>?) ?? const {};
    final g = <String, List<SymptomOption>>{};
    for (final e in (j['groups'] as Map<String, dynamic>).entries) {
      g[e.key] = [
        for (final opt in e.value as List)
          SymptomOption(
            (opt as Map<String, dynamic>)['id'] as String,
            (labels[opt['id']] as String?)?.trim().isNotEmpty == true
                ? labels[opt['id']] as String
                : opt['label'] as String,
          ),
      ];
    }
    return SymptomChecker._(g, [
      for (final p in j['problems'] as List)
        _translated(
          Problem.fromJson(p as Map<String, dynamic>),
          texts[(p)['id']] as Map<String, dynamic>?,
        ),
    ]);
  }

  static Problem _translated(Problem p, Map<String, dynamic>? t) {
    if (t == null) return p;
    String pick(String key, String base) {
      final v = t[key];
      return v is String && v.trim().isNotEmpty ? v : base;
    }

    final steps = t['steps'];
    return Problem(
      id: p.id,
      name: pick('name', p.name),
      category: p.category,
      severity: p.severity,
      what: pick('what', p.what),
      check: pick('check', p.check),
      // Steps are only replaced as a whole, so a half-translated list never shows.
      steps: steps is List &&
              steps.length == p.steps.length &&
              steps.every((x) => x is String && x.trim().isNotEmpty)
          ? [for (final x in steps) x as String]
          : p.steps,
      prevent: pick('prevent', p.prevent),
      worry: pick('worry', p.worry),
      match: p.match,
    );
  }

  static int _sev(String s) => s == 'high' ? 2 : (s == 'med' ? 1 : 0);

  /// Top causes for the selected option ids. Empty when nothing matches
  /// strongly enough, so the app says so instead of guessing.
  List<Diagnosis> rank(Set<String> selected) {
    final scored = <MapEntry<Problem, int>>[];
    final order = <String, int>{};
    for (var i = 0; i < problems.length; i++) {
      final p = problems[i];
      order[p.id] = i;
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
      // Ties keep the knowledge base's own order, never the translated name,
      // so every language gives the same answer.
      return s != 0 ? s : order[a.key.id]!.compareTo(order[b.key.id]!);
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
