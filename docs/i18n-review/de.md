# German (de) string review

Read by hand, line by line, against the English text: 437 of 437 interface strings
(`lib/l10n/app_de.arb`). No helper agents or translation services were used.
Symptom Checker text: see the end of this file.

## Mechanical checks (scripted)
- 437 keys; 0 missing, 0 extra, 0 empty, 0 placeholder mismatches.
- Identical to English: GrowLog, System, Version, Support, Scans. All valid German/loanwords.

## Verdict
No wrong-meaning translations or broken placeholders. Quality is high; German handles "Due now"
("Jetzt fällig") better than es/fr. Main issue is the same register split as Spanish. Nothing changed yet.

## Findings
| # | Key (index) | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| 1 | Register, indexes 3, 30, 54, 109, 132 | "starten Sie", "Tippen Sie ... Ihre erste Pflanze", "Ziehen Sie", "Fügen Sie" (formal Sie) | These 5 are the only formal strings; 58 strings from index 139 on use informal du. Two voices in one app. (Index 426 "Sie ersetzen" is the pronoun "they", not an address; leave it.) | Convert to du: "Bitte starte die App neu oder versuche es erneut", "Tippe auf +, um deine erste Pflanze hinzuzufügen", "Ziehe den Regler...", "Füge weitere Messungen hinzu...", "Füge mindestens 2 Fotos hinzu..." | high |
| 2 | privacyPolicy (82) | Datenschutzrichtlinie | In Germany/EU the standard legal term is "Datenschutzerklärung"; stores and regulators use it | Datenschutzerklärung | medium |
| 3 | Handy vs Telefon: Handy in 277, 419; Telefon in 172, 178, 205, 337, 349, 361, 364, 372 | mixed | Two words for the same thing (2 vs 8) | Use "Telefon" everywhere (majority) | low-medium |
| 4 | noUpcomingCare (106), noOverdueCare (107) | Keine anstehende Pflege / Keine überfällige Pflege | Unidiomatic | Keine anstehenden Pflegeaufgaben / Keine überfälligen Pflegeaufgaben | low-medium |
| 5 | upgradeToPro (86) | Auf Pro upgraden | Anglicism | Auf Pro umsteigen | low (may be unused) |
| 6 | Date composition: photoAccessibility (120), scannedLabel (159) | "Foto vom {date}", "gescannt {date}" | Date is "Heute"/"Gestern"/"Vor 3 Tagen"/"7. Okt": gives "Foto vom Heute", "gescannt Heute" | Code item 5 (shared, all languages) | medium |
| 7 | doctorCheckHealth (246), doctorTitle (253), offHealthNote (374) | Doktor | Reads like a person; | Pflanzendoktor | low |
| 8 | hintFreeTier (293) | Kostenlose Stufe verfügbar | "Stufe" is a literal tier | Kostenloser Tarif verfügbar | low |
| 9 | about (80) | Über | Incomplete on its own | Über die App | low |
| 10 | Ellipsis spacing: spaced in 210, 238, 273; unspaced in 351, 361, 383 | Schaue genau hin … / Startet… | Inconsistent | Pick one style | low |
| 11 | careOverdue (15), careDueToday (14) | "Gießen überfällig" | Nominalised infinitive, acceptable in German; noted only for parity with es/fr | none | info |
| 12 | offStarting (351) vs aiStarting (273) | Startet… vs Wird gestartet … | Same word, different wording | Same wording | low |
| 13 | noVisionWarning (289) | daher ist das Scannen aus | Colloquial "aus" | deaktiviert | low |
| 14 | privacyChoices (435) | Datenschutzoptionen | Standard term is "Datenschutzeinstellungen" | optional | low |
| 15 | paulGreeting (312) | ...komisch aussieht | Slightly casual | seltsam | low |
| 16 | Possibly dead strings | upgradeToPro, aiPlantId, cloudSync, journal strings | Not confirmed unused | none | info |

## Not covered yet
- Symptom Checker labels and problems (assets/care/symptoms_de.json): not read yet.
