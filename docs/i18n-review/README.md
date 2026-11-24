# Language review tracker

All review findings live in this folder: one file per language, `docs/i18n-review/<lang>.md`.
This table is the single place to see where the review stands.

## Plan (agreed order)
1. **Review phase:** read every language one at a time, interface strings (437) and Symptom Checker
   text (59 labels + 41 problems, in `assets/care/symptoms_<lang>.json` against `symptoms.json`).
   Findings go into that language's file. NO string edits during this phase.
2. **Fix phase:** after ALL languages are reviewed, apply every approved fix across all languages in
   ONE commit, with ONE compile check.
3. **Code item, in the same batch:** the date helper (`scanDateLabel`, lib/widgets/scan_widgets.dart)
   returns capitalised "Today"/"Yesterday" and bare dates, so "scanned {date}" reads wrongly in
   every language (fr: "scannée Aujourd'hui", "scannée 7 oct."; en: "scanned Today").
4. **Verify:** one emulator language run after the batch.

## REVIEW PHASE COMPLETE: all 10 translated languages read (437 interface strings + 59 labels + 41 problems each)
English (source) was not reviewed. Nothing below has been applied except French items 1-4. No string edits
have been made in any other language. 262 finding rows in total across the 10 files (counted by script).
Next step is the FIX PHASE (one commit, one compile check), then ONE emulator language run.

## Status
| Lang | UI strings (437) | Symptom text | Findings file | Fixes |
|---|---|---|---|---|
| fr | 437/437 read | 59/59 labels + 41/41 problems read | fr.md | items 1-4 applied early (e234c4d); items 5-11 wait for the batch |
| es | 437/437 read | 59/59 labels + 41/41 problems read | es.md | none yet; dialect decided: Option A Latin American (batch phase) |
| de | 437/437 read | 59/59 labels + 41/41 problems read | de.md | none yet; decided: convert clipped imperatives S1 (batch phase) |
| pt | 437/437 read | 59/59 labels + 41/41 problems read | pt.md | none (batch phase) |
| ar | 437/437 read | 59/59 labels + 41/41 problems read | ar.md | none (batch phase) |
| hi | 437/437 read | 59/59 labels + 41/41 problems read | hi.md | none (batch phase) |
| ja | 437/437 read | 59/59 labels + 41/41 problems read | ja.md | none (batch phase) |
| ko | 437/437 read | 59/59 labels + 41/41 problems read | ko.md | none (batch phase); decision pending: speech level (finding 1) |
| zh | 437/437 read | 59/59 labels + 41/41 problems read | zh.md | none (batch phase) |
| he | 437/437 read | 59/59 labels + 41/41 problems read | he.md | none (batch phase) |
| en | source text, not reviewed | not reviewed | - | - |

## Decisions still open (yours)
- Korean (ko.md finding 1): speech level. Option A 합니다체 everywhere (edits 56 interface strings; my recommendation) or
  Option B 해요체 everywhere (edits about 60 interface + 130 symptom sentences).
- Chinese (zh.md finding 3): the "Treat" label. Default if you do not choose: 防治 (alternative: 处理).
Already decided: Spanish dialect = Option A Latin American; German = convert clipped imperatives (S1).

## Needs a native speaker BEFORE release (I could not verify these from here)
- Hindi S1: "हाला/हाले" for "halo" (may mean liquor).
- Hebrew S1: "ורידים" for leaf veins (blood-vein word), S2 "ותיקים" for older leaves, S4 "קדי עכביש" (possible typo).
- Arabic: the new few/many plural forms and the "مسح" scan/clear decision.
- Every suggested replacement in every file is my own wording, not reviewed by a native speaker.
- Care-guide and Symptom Checker CONTENT (horticultural advice) was reviewed only against the English text, not against a
  published source.

## Patterns that repeat across languages (fix once, apply everywhere)
- Two translation passes: a split near interface index 132-139 shows in es, de, ar, hi, ko, zh, he, ja, pt (register,
  spelling, or terminology). Each file lists its exact index ranges.
- "Treat" (careTypeTreat 22 / treatEvery 66) collides with "Care" in ja, ko, zh, he (same word for both).
- "Wished" (wishedOn 321) is identical to "Added" (addedOn 247) in ar, ja, ko, zh, he.
- "Due now" (dueNow 191/192) is misleading or identical to "Due today" in es, pt, he.
- Rubbing alcohol wording is unsafe or vague in es, pt, ar (S1 in each file); correct in fr, de, hi, ja, ko, zh, he.

## Items that are CODE changes, not translation edits
- scanDateLabel (lib/widgets/scan_widgets.dart:95): capitalised "Today"/"Yesterday" and bare dates inside "scanned {date}"
  (all languages; worst in fr, es, de, pt, hi).
- careDueToday / careOverdue / careDueWithType build a phrase from a verb label ("Regar atrasado"): needs noun forms.
- Arabic: daysSuffix (67) has no count parameter; plural blocks need few/many; 6 numeric strings have no plural block.
- Hebrew: =2 forms missing in 4 plural strings; 4 numeric strings with no plural block.


## FIX PHASE APPLIED (one batch, branch i18n-fixes merged to main)
Counted by script against the previous main: 467 interface strings and 276 symptom-text fields changed in total.
| Lang | Interface strings changed | Symptom fields changed |
|---|---|---|
| fr | 44 | 14 |
| es | 65 | 11 |
| de | 23 | 156 (includes the clipped-imperative conversion) |
| pt | 44 | 23 |
| ar | 69 | 10 |
| hi | 42 | 22 |
| ja | 27 | 17 |
| ko | 72 | 13 |
| zh | 32 | 5 |
| he | 49 | 5 |
Code: scanDateLabel gained an optional `inline` flag (lower-cases the first letter, no effect on uncased scripts),
used at the one place a date is dropped into the middle of a sentence (recent_scans_row.dart, a screen-reader label).
Verified locally by a script mirroring the repo tests (same keys, same placeholders, symptom ids/step counts, text differs
from English). The REAL check is the CI compile check plus the emulator language run, see results in the commit history.

Decisions applied by default (you had not answered): Korean = Option A (formal 합니다체 everywhere; three user-voice chat
starters 307/308/310 kept conversational), Chinese Treat label = 防治.

### NOT applied, and why
- Verb-label-as-noun phrases ("Regar atrasado": careDueToday/careOverdue/careDueWithType): needs new noun-form keys for the
  six care types in all 11 languages. Design decision, not done.
- Bare dates in "scanned {date}" ("scannée 7 oct."): needs a per-language "on" word; not done. Only the capitalised
  Today/Yesterday case is fixed.
- Hebrew: ורידים (leaf veins), ותיקים (older leaves), קדי עכביש (typo?), and the 16 symptom uses of גידול: left unchanged
  until a native speaker confirms (I could not verify them). Hebrew offCareWater/offCareFeed (389/390) keep a static
  "ימים" because their `days` placeholder is typed String in the English template (a plural needs a numeric type).
- Arabic 389/390 reworded number-neutral for the same reason; Arabic schedule labels reworded to noun phrases + "بالأيام"
  so no code change was needed.
- Corrected review finding: German "Weiße Fliege" is a fixed capitalised pest name, so de S8 was wrong and was NOT applied.
- Skipped as subjective or info-level: es S6/S8, fr style item 8, pt Doutor naming and "rega", hi S8 (हनीड्यू), ko
  clear/delete verbs, ja clear/delete verbs, he theme words, ar offline wording.
- Hindi S1 (हाला -> घेरा) WAS applied but still needs a native speaker to confirm.


### Verification of the fix batch (main e6903e6)
- Compile check (run 45044316055): ALL CHECKS PASSED. gen-l10n generated all 11 localization files, including Arabic
  few/many plurals, Hebrew dual forms and the nested plural in photosCount/photosSpan. 88 unit tests passed.
- Emulator language run (run 45045269908): SUMMARY pass=69 fail=0 notfound=0, overflow lines 0. The 36 error lines are
  all the Android UiAutomation harness crash ("Bad file descriptor"); 0 lines come from GrowLog. The run checks the dock
  and tab labels in all 11 languages for system language, manual choice, restart and phone default, plus the Swahili and
  Traditional-Chinese fallbacks. It does NOT read the long new strings.
- Looked at by eye: Hebrew first launch (RTL, plural imperatives, no overflow) and Korean first launch (formal speech
  level, no overflow). Arabic, Chinese and the other languages were not looked at in this run.
- Cosmetic, not caused by this batch: Korean text wraps inside a word ("연결 / 하세요").
- Still NOT verified: any of the new wording by a native speaker; the long new strings (plural forms, schedule labels) on a
  screen; Plant Page, Add Plant schedule row and Symptom Checker in the changed languages; a real phone.


### Verification: screens in all 10 languages (run 45254847465 on main 4865e20)
Script: .github/scripts/emulator_screens.sh (+ screens_check.py). It creates one plant in English, then for each of ar, he, ko, zh,
ja, de, hi, fr, es, pt it checks Home, Plant Page, Add Plant, Schedule and a full Symptom Checker run (4 steps) to a results
screen, for the expected localized text (from the ARB files and the symptom overlay files), English leaks, and overflow.
- RESULT: SUMMARY pass=80 fail=0 notfound=0; overflow lines 0; error lines 0 (0 GrowLog-related).
- Items found: 100% on Home, Plant Page, Schedule and every Symptom Checker step in all 10 languages (the Symptom Checker run
  reaches a result and finds the translated "Overwatering" name). Add Plant found 4 of 6 in every language: the two always-missed
  items are the empty text-field floating labels (plantNameLabel, speciesLabel), which the accessibility dump does not expose;
  they are visible in the screenshots (Korean, Hindi).
- Looked at by eye: Arabic results (RTL, translated problem, "ممكن"), Korean Add Plant, Hindi Add Plant (relabelled schedule rows,
  "पानी देने का अंतराल 7 दिन"), Japanese results, Korean/Hebrew home. All render correctly with no overflow.
- The FIRST run of this script failed 17 checks. All 17 were bugs in my script, not the app: (1) in ko/zh/ja/hi the Scans tab label is
  contained in the centre camera button's label, so the tap opened the identification sheet (fixed in ui_tap.py: a repeated tab label
  now counts as an exact match); (2) the German Plant Page tap hit the "Next: Water Fern" text (fixed: open the plant via its card label).
- NOT exercised by this run: Scan result and Doctor (need a model or an AI key), Settings, Connect AI, Paul chat, Wishlist and Rooms,
  Growth/Doctor history (need photos), and the count-dependent plural strings (Arabic few/many, Hebrew dual: need overdue care,
  several plants or photos). Native-speaker review of all wording is still outstanding. Nothing has run on a real phone.
