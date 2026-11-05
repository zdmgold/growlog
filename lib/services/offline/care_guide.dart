import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum CareLight { brightIndirect, medium, low, direct }

/// General starting points for one species. They are guidance for typical indoor
/// conditions, not exact rules: the plant page lets the person change them.
class CareEntry {
  final String species;
  final String common;
  final CareLight light;
  final int waterDays;

  /// Null when the plant should not be fed on a schedule.
  final int? feedDays;

  const CareEntry({
    required this.species,
    required this.common,
    required this.light,
    required this.waterDays,
    required this.feedDays,
  });

  factory CareEntry.fromJson(Map<String, dynamic> j) {
    final feed = (j['feedDays'] as num).toInt();
    return CareEntry(
      species: j['species'] as String,
      common: j['common'] as String,
      light: lightFromKey(j['light'] as String),
      waterDays: (j['waterDays'] as num).toInt(),
      feedDays: feed > 0 ? feed : null,
    );
  }
}

CareLight lightFromKey(String k) {
  switch (k) {
    case 'bright_indirect':
      return CareLight.brightIndirect;
    case 'medium':
      return CareLight.medium;
    case 'low':
      return CareLight.low;
    case 'direct':
      return CareLight.direct;
  }
  throw FormatException('Unknown light level: $k');
}

/// Bundled care guide for the species the offline model can identify.
class CareGuide {
  CareGuide._();
  static final CareGuide instance = CareGuide._();

  Map<String, CareEntry>? _byName;

  Future<void> load() async {
    if (_byName != null) return;
    try {
      final raw = await rootBundle.loadString('assets/care/care_guide.json');
      _byName = parse(raw);
    } catch (e) {
      debugPrint('CareGuide.load failed: $e');
      _byName = {};
    }
  }

  static Map<String, CareEntry> parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final p in (j['plants'] as List))
        (p as Map<String, dynamic>)['species'] as String: CareEntry.fromJson(p),
    };
  }

  CareEntry? lookup(String species) => _byName?[species];

  /// Species whose common or Latin name matches the typed text, best first.
  List<CareEntry> search(String query, {int limit = 5}) =>
      searchIn(_byName?.values ?? const [], query, limit: limit);

  /// Names that start with the text rank above names that merely contain it.
  /// Needs at least two characters so one stray letter does not list everything.
  static List<CareEntry> searchIn(Iterable<CareEntry> entries, String query,
      {int limit = 5}) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    final starts = <CareEntry>[];
    final contains = <CareEntry>[];
    for (final e in entries) {
      final names = [e.common.toLowerCase(), e.species.toLowerCase()];
      if (names.any((n) => n.startsWith(q) || n.split(' ').any((w) => w.startsWith(q)))) {
        starts.add(e);
      } else if (names.any((n) => n.contains(q))) {
        contains.add(e);
      }
    }
    return [...starts, ...contains].take(limit).toList();
  }
}
