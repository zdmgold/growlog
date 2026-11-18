# French (fr) string review

Read by hand, line by line, against the English text. 437 of 437 interface strings read
(`lib/l10n/app_fr.arb`). No helper agents or translation services were used.
Symptom Checker content (59 labels, 41 problems) is NOT covered here; see the end.

## Mechanical checks (scripted, all 10 languages)
- 437 keys in every file; 0 missing, 0 extra, 0 empty values, 0 placeholder mismatches.
- Strings identical to English in fr: GrowLog, Photos, Notifications, Version, Scans, Flash,
  Notes, "{count} photos", Possible. All are valid French or brand names; none is untranslated.

## Verdict
No wrong-meaning translations, no untranslated strings, no broken placeholders found.
Findings below are wording, consistency and context issues. Nothing has been changed yet.

## Findings (to approve before editing)
| # | Key (index) | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| 1 | shareDefaultText (114) | Ma croissance de plante avec GrowLog | Awkward word order | La croissance de ma plante avec GrowLog | medium |
| 2 | healthAttention (158) | Demande de l'attention | Unnatural | Nécessite de l'attention | low-medium |
| 3 | lightBrightIndirect (234) | Indirecte lumineuse | Unnatural; "Lumière" label precedes it | Vive, indirecte | medium |
| 4 | addToWishlist (318) | Ajouter à la liste d'envies | Term differs from navWishlist/wishlistTitle/addWish ("liste de souhaits") | Ajouter à la liste de souhaits | medium |
| 5 | scannedLabel (159), via scanDateLabel | {name}, scannée {date} | Date text is "Aujourd'hui" / "Hier" / "Il y a 3 jours" / "7 oct."; yields "scannée Aujourd'hui" (capital) and "scannée 7 oct." (needs "le") | Code issue, not a pure translation fix; see note | medium |
| 6 | Title Case (28, 31, 56, 69, 77-79, 82, 85, 87, 94, 101, ...) | Mon Jardin, Ajouter une Plante, Sauvegarde et Restauration | French uses sentence case | Lowercase after first word | low (style) |
| 7 | Apostrophes | mix of ' (2, 3, 60, 102, 337-365) and ’ elsewhere | Inconsistent typography | Use ’ everywhere | low |
| 8 | dueNow (191) vs dueNowCount (192) | À faire maintenant / À faire · {count} | Fine, noted only because the tab title shortens it | none | info |
| 9 | noSpeciesMatch (417) | ...saisir la vôtre | "la vôtre" has no clear antecedent | ...saisir le nom vous-même | low |
| 10 | offNoInternetNeeded (362) | Aucun internet nécessaire | Slightly odd | Aucune connexion internet nécessaire | low |
| 11 | plusMore (185) | +{count} de plus | Acceptable; "+{count} autres" is more natural | optional | low |

Note on #5: `scanDateLabel` (lib/widgets/scan_widgets.dart:95) returns capitalised "Today"/"Yesterday"
and a bare date, and is dropped into "scanned {date}" / "{name}, scannée {date}". English shows
"scanned Today". This needs a code decision, not a translation edit.

## Possibly dead strings (naive search, NOT confirmed)
56 keys have no reference in lib/ outside lib/l10n/ (for example upgradeToPro, aiPlantId,
cloudSync, the Journal strings). The search is crude (it would miss dynamic lookups), and
navSettings is used by the language test, so do not delete anything from this list unreviewed.

## Not covered
- Symptom Checker labels and problem text (lib/data/symptom_i18n/fr or equivalent): not yet read.
- Screens: French has not been looked at on an emulator beyond the dock and Garden/Schedule
  tabs (language test run 44412505316: fr first launch, manual choice, restart, phone default all PASS).
