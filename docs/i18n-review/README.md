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
