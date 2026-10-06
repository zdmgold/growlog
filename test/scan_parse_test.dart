import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/models/care_log_model.dart';
import 'package:growlog/models/plant_model.dart';
import 'package:growlog/models/scan_record.dart';
import 'package:growlog/services/scan_service.dart';

ScanRecord parse(String raw) =>
    ScanService.parse(raw, id: 'x', imagePath: '/tmp/x.jpg');

void main() {
  test('parses a well-formed answer', () {
    final r = parse('''
IS_PLANT: yes
SPECIES: Monstera
LATIN: Monstera deliciosa
CONFIDENCE: High
HEALTH: Needs attention
ISSUE: Spider mites
SEVERITY: Medium
SUMMARY: A large leafy plant. It has fine webbing on the leaves.
WATER_DAYS: 7
FERTILIZE_DAYS: 30
LIGHT: Bright indirect
TREATMENT:
1. Wipe the leaves
2. Use insecticidal soap
PREVENTION:
1. Raise humidity
''');
    expect(r.isPlant, isTrue);
    expect(r.commonName, 'Monstera');
    expect(r.latinName, 'Monstera deliciosa');
    expect(r.health, ScanHealth.attention);
    expect(r.issue, 'Spider mites');
    expect(r.waterDays, 7);
    expect(r.fertilizeDays, 30);
    expect(r.treatment, ['Wipe the leaves', 'Use insecticidal soap']);
    expect(r.prevention, ['Raise humidity']);
  });

  test('tolerates markdown bold and "None" issues', () {
    final r = parse('''
**IS_PLANT:** yes
**SPECIES:** Snake plant
**HEALTH:** Healthy
**ISSUE:** None
**WATER_DAYS:** about 14 days
''');
    expect(r.commonName, 'Snake plant');
    expect(r.health, ScanHealth.healthy);
    expect(r.hasIssue, isFalse);
    expect(r.waterDays, 14);
  });

  test('a non-plant photo is flagged', () {
    expect(parse('IS_PLANT: no').isPlant, isFalse);
  });

  test('clamps unrealistic watering intervals', () {
    expect(parse('WATER_DAYS: 400').waterDays, 60);
    expect(parse('WATER_DAYS: 0').waterDays, 1);
  });

  test('ScanRecord survives a database round trip', () {
    final r = parse('SPECIES: Fern\nHEALTH: Watch\nTREATMENT:\n1. Mist daily');
    final back = ScanRecord.fromMap(r.toMap());
    expect(back.commonName, 'Fern');
    expect(back.health, ScanHealth.watch);
    expect(back.treatment, ['Mist daily']);
  });

  test('care schedule starts from the day the plant was added', () {
    final added = DateTime(2026, 1, 1);
    final p = Plant(
      id: 'p',
      name: 'Fern',
      acquiredDate: added,
      createdAt: added,
      waterFrequencyDays: 7,
    );
    expect(p.nextWaterDate, DateTime(2026, 1, 8));
    final watered = p.copyWith(careLogs: [
      CareLog(
        id: 'l',
        plantId: 'p',
        type: CareType.water,
        date: DateTime(2026, 1, 5),
      ),
    ]);
    expect(watered.nextWaterDate, DateTime(2026, 1, 12));
  });
}
