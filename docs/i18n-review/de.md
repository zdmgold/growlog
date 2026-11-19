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


## Symptom Checker review (assets/care/symptoms_de.json against assets/care/symptoms.json)
Read by hand: 59/59 labels, 41/41 problems (name, what, check, prevent, worry, every step).
Scripted: 329 fields compared, every number matches English (cm, minutes, days, deg C, 1 teaspoon
Natron per litre, 2 cm), every step count matches, no meaning reversals. Terminology is strong:
Bittersalz (Epsom salt), Wollläuse, Schildläuse, Trauermücken, Rußtau, Honigtau, Echter Mehltau,
Anthraknose, Grauschimmel are all the correct German terms. Pest treatments stay conservative.

| # | Where | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| S1 | Whole file: 68 texts use clipped du-imperatives ("Prüf", "Nutz", "Wähl", "Rück", "Steiger", "Isolier", "Kontrollier", "Sprüh", "Spül", "Wisch") vs only 2 with full forms | Prüf die Erde | The interface strings use full forms ("Prüfe", "Wähle", "Nutze"). The symptom text is more colloquial; the two voices differ. Clipped forms are not wrong (normal for strong verbs like Heb, Steck, Halt) but forms like "Prüf/Nutz/Wähl/Rück/Steiger" read as slang | DECISION MADE: CONVERT (apply in the batch phase). Options were: keep colloquial, or convert the non-strong-verb ones to full forms (Prüfe, Nutze, Wähle, Rücke, Steigere, Isoliere, Kontrolliere, Sprühe, Spüle, Wische) | medium (consistency) |
| S2 | root_rot step 2; rootbound prevent and step 1; compacted_soil step 2 | "Topf sie in frische... um", "Topf je nach Wachstum... um", "Topf in einen Topf eine Nummer größer... um", "Topf in frische, lockere Erde... um" | Sentence-initial "Topf" (imperative of umtopfen) reads as the noun "pot"; step 1 of rootbound has "Topf in einen Topf" | "Topfe sie in frische... um" / "Topfe die Pflanze alle ein bis zwei Jahre im Frühjahr um" / "Topfe sie in einen Topf eine Nummer größer um" | medium |
| S3 | mealybugs step 2; scale step 2 | in Spiritus getränkten Wattestäbchen | Common German advice but Brennspiritus strength varies (about 94 %) and is denatured | in Isopropanol (70 %) getränkten Wattestäbchen | low-medium |
| S4 | label low_light | Schattiger Standort | Means "shady spot", not strictly "low light" | Standort mit wenig Licht | low |
| S5 | label yellowing | Gelbe Blätter | Loses the process ("yellowing") | Vergilbende Blätter | low |
| S6 | label hot_spot | Nahe einer Heizung oder sehr heißer Platz | Mixed grammar | In der Nähe einer Heizung oder an einem sehr heißen Platz | low |
| S7 | underwatering (prevent) | in kleinen Schlucken | Literal "sips" | in kleinen Mengen | low |
| S8 | whiteflies (name, check) | Weiße Fliegen / deutet auf Weiße Fliegen | Capital W mid-sentence | weiße Fliegen in running text | low |
| S9 | light_change (check) | Lichtverhältnisse der Jahreszeit | Awkward | Licht (z. B. durch die Jahreszeit) | low |
| S10 | underwatering (worry) | trocken | EN says "crisp" | knusprig | low |
