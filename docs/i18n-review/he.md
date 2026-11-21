# Hebrew (he) string review

Read by hand, line by line, against the English text: 437 of 437 interface strings
(`lib/l10n/app_he.arb`). No helper agents or translation services were used.
Right-to-left. Gender: the voice of Paul is masculine ("אני פול", "אני לא בטוח"), consistent.
Symptom Checker text: see the end of this file.

## Mechanical checks (scripted)
- 437 keys; 0 missing, 0 extra, 0 empty, 0 placeholder mismatches. Only identical string: GrowLog.
- Dual forms (=2) exist in 7 plural strings (יומיים, שבועיים, חודשיים, שנתיים, שני צמחים).
- Typography: 0 ASCII apostrophes inside Hebrew words; the geresh is used correctly (155, 276, 314, 315).
  Hyphenated prefixes before Latin names (ל-{name}, ב-{name}) are consistent.
- offProgress (352) is in the CORRECT order ("{done} MB מתוך {total} MB").
- RTL layout and the language switching were already exercised on the emulator language run (he PASS).

## Verdict
No wrong-meaning translations and no broken placeholders. Quality is high and idiomatic (מה שלום {name},
מסתדר עם אור חלש, חבילת הגלישה). Findings are the same two-pass signature as the other languages
(singular vs plural address), plus gender and plural details specific to Hebrew. Nothing changed yet.

## Findings
| # | Key (index) | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| 1 | Address: masculine-singular imperatives in 12 strings (1, 3, 27, 30, 33, 54, 59, 109, 132, 405, 415, 433); inclusive plural in 58 (139-416) | נסה שוב / הוסף / בחר חדר / הצג תוצאות / התחל מחדש | Two address styles in one app; the plural ("נסו", "שלכם") is the gender-neutral convention used by the later strings | Convert the 12 to plural: נסו שוב, אנא הפעילו מחדש..., הציגו הכל, הקישו... הצמח הראשון שלכם (30 also "שלך" -> "שלכם"), סמנו כמת, גררו, בחרו חדר, הוסיפו, הציגו תוצאות, התחילו מחדש, נקו | medium |
| 2 | Plant name + masculine verb: deleteScanMessage (161), plantDeletedSnack (182), addedToGarden (208), plantRemovedSnack (323); also growthEmpty (267) "גדל" | {name} נמחק / נוסף / הוסר / יוסר | {name} is an arbitrary plant name; a feminine name (אלוורה, מונסטרה) needs "נמחקה". Same limitation as the feminine participles in es/fr/pt | Add the masculine noun: "הצמח {name} נמחק" etc. | medium-low |
| 3 | careTypeTreat (22), treatEvery (66) | טיפול / טיפול כל | "Treat" is the same word as "Care" (27 strings use טיפול, plus טיפולים in 106, 107) | ריפוי / ריפוי כל | medium |
| 4 | Growth: גידול in 8 strings (47, 51, 54, 55, 110, 114, 115, 132); צמיחה in 252 | הגידול של הצמח / צמיחה | גידול is also the word for "tumour" in medical Hebrew; צמיחה is the safer plant word and already used once | צמיחה (replace the 8) | medium-low |
| 5 | confidenceHigh/Medium/Low (216-218) | ביטחון גבוה / בינוני / נמוך | ביטחון = security/self-confidence, not statistical confidence | ודאות גבוהה / בינונית / נמוכה | medium-low |
| 6 | dueNow (191), dueNowCount (192), dueToday (255) | להיום / להיום · {count} / להיום | "Due now" includes overdue items; it is identical to "Due today" | 191/192: לביצוע עכשיו / לביצוע · {count} | medium-low |
| 7 | speciesNotSet (200) vs speciesLabel (58) | הזן לא הוגדר / מין | הזן = cultivar/variety; species is מין (used in 58) | המין לא הוגדר | low-medium |
| 8 | Plural forms: =2 missing in statusDue (141), overdueDays (199), everyNDays (230), plantCountLabel (333); no plural at all in photosCount (270), photosSpan (271), offCareWater (389), offCareFeed (390) | באיחור של 2 ימים / כל 2 ימים / {count} תמונות / כל {days} ימים | Standard Hebrew says יומיים / שני צמחים; "1 תמונות" and "כל 1 ימים" are wrong. Milder than Arabic (only 1 and 2 break) | Add =2 forms (באיחור של יומיים, כל יומיים, שני צמחים) and plural blocks for 270, 271, 389, 390 | low-medium |
| 9 | wishedOn (321) | נוספה: {date} | Loses "wish"; near-identical to addedOn (247 "נוסף:") | נוספה לרשימה: {date} | low-medium |
| 10 | upcoming (103) | קרוב | "near" as a tab label | קרובים / בקרוב | low-medium |
| 11 | lightBrightIndirect (234) | עקיף בהיר | Reversed order; 392 already has the natural "אור בהיר עקיף" | בהיר עקיף | low-medium |
| 12 | doctorCheckHealth (246), doctorTitle (253), offHealthNote (374) | רופא | Reads like a human physician | רופא הצמחים | low |
| 13 | themeSystem (73); theme (72) vs headerToLight/Dark (143, 144) | מערכת / ערכת נושא vs עיצוב | "System" is terse; two words for theme | לפי המערכת; unify to ערכת נושא | low |
| 14 | AI: Latin "AI" in 14 strings, בינה מלאכותית in 2 (89, 407) | mixed | Two spellings | AI | low |
| 15 | Phone: טלפון in 10 strings, מכשיר in 171 | mixed | Two words | טלפון | low |
| 16 | "all": הכל (27, 105) vs הכול (187) | mixed | Two spellings; הכול is the Academy standard | הכול | low |
| 17 | searchHint (24) | חיפוש צמחים... | ASCII three dots; six others use … | חיפוש צמחים… | low |
| 18 | symptomNothingFound (407) | לא הצלחתי לצמצם | Missing object | לא הצלחתי לצמצם את האפשרויות | low |
| 19 | Date composition: scannedLabel (159) | {name}, נסרק {date} | Reads correctly with היום / אתמול; no problem in Hebrew | none | info |
| 20 | Possibly dead strings | proFeatures, upgradeToPro, aiPlantId, cloudSync, journal strings | Not confirmed unused | none | info |


## Symptom Checker review (assets/care/symptoms_he.json against assets/care/symptoms.json)
Read by hand: 59/59 labels, 41/41 problems (name, what, check, prevent, worry, every step).
Scripted: 329 fields compared; 328 have identical digits. The one difference is correct (English
"1 teaspoon" is written "כפית", powdery_mildew step 4). Hebrew also writes many quantities as number
words, which a digit check cannot see, so those were read BY HAND against the English: שלוש או ארבע
פעמים, לפחות חודשיים, ארבעה עד שישה שבועות, שישה שבועות, שבועיים, כחודש, כל שנה או שנתיים, כל
שבוע או שבועיים, שבוע (a week), מעבר לחודש, שישה חודשים (label): all match. Every step count matches,
no meaning reversals. The file is fully plural-address (34 plural imperatives, 0 singular), which
supports interface finding 1. Terminology is strong: ריקבון שורשים, בצקת, פקקיות, עקת חום, יסודות קורט,
מלח אפסום, ברזל קלאטי, כנימות קמח, כנימות מגן, כנימות עלה, כנימות עש, יתושי פטריות, תריפסים, קמחונית,
חלודה, אנתרקנוז, עובש פיח, טל דבש, הילה, הלם החלפת עציץ, תרדמת חורף. "אלכוהול רפואי" is an explicit
term for rubbing alcohol (no safety flag, unlike es/pt/ar). "אין מה למנוע" is natural (unlike Arabic).

| # | Where | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| S1 | "ורידים" for leaf veins: 7 uses in 4 problems (iron_deficiency, magnesium_deficiency, scale, bacterial_leaf_spot) + label loc_between_veins | בין הורידים הירוקים | ורידים is the word for blood veins; I believe the usual botanical word for leaf veins is עורקים (עורקי העלה). CONFIRM WITH A NATIVE SPEAKER, I cannot verify it from here | עורקי העלה / העורקים הירוקים (if confirmed) | medium (verify) |
| S2 | "ותיקים" for older leaves: 6 uses in 3 problems (nitrogen_deficiency, magnesium_deficiency, old_leaf_drop) + label age_old | עלים ותיקים | ותיק = veteran/long-standing; unusual for leaves. CONFIRM | עלים ישנים / בוגרים | low-medium (verify) |
| S3 | chewing_pests (what) | מזיקים גדולים יותר כרסמים חורים | "כרסמים" reads as the noun "rodents": "larger pests, rodents, holes" | מזיקים גדולים יותר אוכלים חורים או שוליים מרוטים בעלים | medium-low |
| S4 | spider_mites (name) | אקריות (קדי עכביש) | "קדי" looks like a typo (a missing letter). CONFIRM | אקריות (קרדיות עכביש) | low-medium (verify) |
| S5 | whiteflies (worry) | אם ההדבקה נמשכת | הדבקה = infection; for pests the word is נגיעות (הדבקה is right in bacterial_leaf_spot) | אם הנגיעות נמשכת | low |
| S6 | label hot_spot; low_humidity (step 1); heat_stress (check) | ליד תנור / מתנורים / ליד תנור | תנור = oven/stove; a heater is תנור חימום (heat_stress check also names רדיאטור, which clarifies it) | ליד תנור חימום | low |
| S7 | "growth": גידול 16 uses in the symptom text (+ labels leggy, no_growth) vs גדילה 2, צמיחה 0 | גידול חדש / גידול איטי | Same issue as interface finding 4 (גידול also means tumour). NOT a blind replace: עציץ הגידול (grow pot, #18) is correct | Decide with finding 4; keep עציץ הגידול | low-medium |
| S8 | labels long_unfed, heavy_feed | לא דישנו / דישנו הרבה | Impersonal "they fertilised" vs the passive (הועבר, נקנה) used in neighbouring labels | לא דושן / דושן הרבה (optional) | low |
| S9 | mineral_crust (worry) | ממשיכים להשחים | "darkening" for "browning" (same slight shift as es/pt/ar) | ממשיכים להחוויר... see native speaker | low |
