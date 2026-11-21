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
| ko | 437/437 read | not read | ko.md | none (batch phase); decision pending: speech level (finding 1) |
| zh | not started | not started | - | - |
| he | not started | not started | - | - |
| en | source text, not reviewed | not reviewed | - | - |
