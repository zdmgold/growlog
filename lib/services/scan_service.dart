import 'dart:typed_data';
import '../models/scan_record.dart';
import 'ai/ai_client.dart';
import 'ai/ai_settings.dart';

/// Identifies a plant and checks its health from one photo.
class ScanService {
  static const _prompt = '''
You are Paul, a plant expert. Look at this photo.
If it does not show a plant, answer IS_PLANT: no and nothing else.
Otherwise identify the plant and judge its health from what is visible.

Respond in this EXACT format, one item per line:

IS_PLANT: yes
SPECIES: [common name]
LATIN: [scientific name]
CONFIDENCE: [High / Medium / Low]
HEALTH: [Healthy / Watch / Needs attention]
ISSUE: [the main problem, or None]
SEVERITY: [None / Low / Medium / High / Critical]
SUMMARY: [2 sentences about the plant and its condition]
WATER_DAYS: [typical days between waterings, a number]
FERTILIZE_DAYS: [typical days between feedings, a number]
LIGHT: [Low / Medium / Bright indirect / Direct sun]
TREATMENT:
1. [step, or "No treatment needed"]
2. [step]
PREVENTION:
1. [tip]
2. [tip]
''';

  static Future<ScanRecord> analyze(
    Uint8List jpegBytes, {
    required String id,
    required String imagePath,
    String? plantId,
  }) async {
    final settings = AiSettings.instance;
    final client = settings.client;
    if (client == null) {
      throw const AiException('Add your API key first to scan plants.');
    }
    if (!settings.supportsVision) {
      throw const AiException(
        'The connected AI model cannot read photos. Connect a different provider or model.',
      );
    }
    final text = await client.complete(
      messages: const [AiMessage('user', _prompt)],
      image: jpegBytes,
      maxTokens: 900,
    );
    return parse(text, id: id, imagePath: imagePath, plantId: plantId);
  }

  static int? _days(String v, int min, int max) {
    final m = RegExp(r'\d+').firstMatch(v);
    if (m == null) return null;
    final n = int.tryParse(m.group(0)!);
    if (n == null) return null;
    return n.clamp(min, max);
  }

  static ScanHealth _health(String v) {
    final s = v.toLowerCase();
    if (s.contains('healthy') && !s.contains('un')) return ScanHealth.healthy;
    if (s.contains('watch') || s.contains('minor') || s.contains('eye')) {
      return ScanHealth.watch;
    }
    return ScanHealth.attention;
  }

  static String _clean(String v) {
    final s = v.trim();
    final low = s.toLowerCase();
    if (low == 'none' || low == 'n/a' || low == 'unknown' || low == '-') return '';
    return s;
  }

  /// Turns the AI's formatted answer into a [ScanRecord]. Tolerates markdown
  /// bold, extra spaces and missing lines.
  static ScanRecord parse(
    String raw, {
    required String id,
    required String imagePath,
    String? plantId,
  }) {
    final values = <String, String>{};
    final treatment = <String>[];
    final prevention = <String>[];
    String? section;

    final bullet = RegExp(r'^(-|\u2022|\d+[.)])\s*');
    final lines = raw
        .replaceAll('**', '')
        .replaceAll('#', '')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);

    for (final line in lines) {
      if (bullet.hasMatch(line)) {
        final item = line.replaceFirst(bullet, '').trim();
        if (item.isEmpty) continue;
        if (section == 'treatment') treatment.add(item);
        if (section == 'prevention') prevention.add(item);
        continue;
      }
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final key = line.substring(0, idx).trim().toUpperCase().replaceAll(' ', '_');
      final value = line.substring(idx + 1).trim();
      if (key == 'TREATMENT') {
        section = 'treatment';
        if (value.isNotEmpty) treatment.add(value);
      } else if (key == 'PREVENTION') {
        section = 'prevention';
        if (value.isNotEmpty) prevention.add(value);
      } else {
        section = null;
        values[key] = value;
      }
    }

    final isPlant = !(values['IS_PLANT'] ?? 'yes').toLowerCase().startsWith('n');
    final name = _clean(values['SPECIES'] ?? '');
    final latin = _clean(values['LATIN'] ?? '');
    final issue = _clean(values['ISSUE'] ?? '');
    final health = _health(values['HEALTH'] ?? 'healthy');

    return ScanRecord(
      id: id,
      plantId: plantId,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      isPlant: isPlant,
      commonName: name.isEmpty ? 'Unknown plant' : name,
      latinName: latin.isEmpty ? null : latin,
      confidence: _clean(values['CONFIDENCE'] ?? '').isEmpty
          ? 'Medium'
          : _clean(values['CONFIDENCE'] ?? ''),
      health: health,
      issue: issue,
      severity: _clean(values['SEVERITY'] ?? '').isEmpty
          ? 'None'
          : _clean(values['SEVERITY'] ?? ''),
      summary: values['SUMMARY'] ?? '',
      treatment: treatment,
      prevention: prevention,
      waterDays: _days(values['WATER_DAYS'] ?? '', 1, 60),
      fertilizeDays: _days(values['FERTILIZE_DAYS'] ?? '', 7, 180),
      light: _clean(values['LIGHT'] ?? '').isEmpty
          ? null
          : _clean(values['LIGHT'] ?? ''),
    );
  }
}
