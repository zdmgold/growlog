# Arabic (ar) string review

Read by hand, line by line, against the English text: 437 of 437 interface strings
(`lib/l10n/app_ar.arb`). No helper agents or translation services were used.
Modern Standard Arabic, masculine-singular imperatives throughout (consistent, no register split).
Symptom Checker text: see the end of this file.

## Mechanical checks (scripted)
- 437 keys; 0 missing, 0 extra, 0 empty, 0 placeholder mismatches. Only identical string: GrowLog.
- Dual forms are used well where present (يومين, أسبوعين, شهرين, سنتين, نباتان, خطا Fraunces وInter).

## Verdict
No wrong-meaning translations except finding 4. The strongest issues are GRAMMAR OF NUMBERS (plural
forms) and TERMINOLOGY collisions. Right-to-left layout was already seen working on device and on
the emulator (header, dock, alignment all mirror correctly). Nothing has been changed yet.

## Findings
| # | Key (index) | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| 1 | Plural forms. 4 strings define only =1/other: statusDue (141), overdueDays (199), everyNDays (230), plantCountLabel (333). 7 define =1/=2/other: daysAgo, weeksAgo, monthsAgo, yearsAgo (6-9), careDueInDays (13), careDueWithType (16), roomCardAccessibility (119). | "other" = أيام / نباتات | Arabic has 6 forms. With only =1,=2,other, 3-10 is right but 11-99 and 100+ are wrong ("قبل 15 أيام", "{count} نباتات تحتاج" for 12). The 4 strings also lack =2 ("2 plants need care" has no dual). | Add few (3-10: أيام), many (11-99: يومًا), other (100+: يوم) and =2/=0 where needed | medium-high (grammar) |
| 2 | Numbers with NO plural: photosCount (270) "{count} صور", photosSpan (271) "{count} صور خلال {days} يومًا", offCareWater (389) "كل {days} أيام", offCareFeed (390) | static word | "1 صور", "2 صور" wrong; "خلال 5 يومًا" wrong (يومًا is only right for 11-99); "كل 14 أيام" wrong | Convert to plural blocks (few/many/other) | medium-high |
| 3 | daysSuffix (67), used after "كل" in the schedule steppers (61-66) | أيام | No count parameter. The most common values (14, 30) read "كل 14 أيام" (should be "كل 14 يومًا") | Code item: replace with a plural key that takes the count | medium-high (code) |
| 4 | offIdentifying (361) | جارٍ التعرّف على هذا الهاتف… | "التعرّف على X" = identify X, so this says "identifying THIS PHONE" | جارٍ التعرّف على النبتة على هذا الهاتف… (or: جارٍ التعرّف باستخدام هذا الهاتف…) | medium |
| 5 | "مسح" means both scan and clear. Scan: 135, 139, 163, 168, 197, 407. Clear: 130, 166, 303, 314, 432, 433. The Scans tab/"My scans" use فحص (134, 150, 145) | مسح نبتة vs مسح البحث | One word for two opposite actions; two words for one concept | DECISION: use فحص (as the Scans tab) for scan and keep مسح only for clear | medium |
| 6 | Plant noun: نبتة in 23 strings (mostly index 135+), singular نبات in 18 (mostly 28-132) | إضافة نبات vs امسح نبتة | Same split pattern as the original/later passes in es/de. "نبتة" = one plant, "نبات" = plant (generic) | Use نبتة for a single plant everywhere | medium-low |
| 7 | Wishlist: الرغبات in 43, 98, 100; الأمنيات/أمنية in 318, 319 | قائمة الرغبات vs قائمة الأمنيات | Two terms for the same list | Unify to الرغبات (majority) | medium-low |
| 8 | wishedOn (321) | أُضيفت: {date} | Identical to addedOn (247); loses "wish" | أُضيفت إلى القائمة: {date} | low-medium |
| 9 | Watering: سقي in 17, 61, 307, 389; ري in 190, 312 | جدول ري / عن الري | Two terms | Unify to سقي | low-medium |
| 10 | lightBrightIndirect (234) | غير مباشر ساطع | Reversed order; 392 has the natural "ضوء ساطع غير مباشر" | ساطع غير مباشر | low-medium |
| 11 | offLikely (375) vs symptomPossible (409) | محتمل / محتمل | "Likely" and "Possible" identical | 409: ممكن | low-medium |
| 12 | Phone: الهاتف in 10 strings, الجوال in 344 | بيانات الجوال | Two words | بيانات الهاتف المحمول / بيانات الهاتف | low |
| 13 | licencesAndCredits (420) | التراخيص والشكر | "credits" as "thanks" is odd | التراخيص والإشادات | low |
| 14 | markCareDone (257, 186) | كمنجز | Stiff | كمكتمل | low |
| 15 | doctorTitle (253), doctorCheckHealth (246), offHealthNote (374) | الطبيب | Reads like a person | طبيب النبات | low |
| 16 | noPlantsFilter (181) vs roomsFilterLabel (201) | الفلتر / تصفية | Transliteration vs Arabic | التصفية | low |
| 17 | Offline wording: "دون اتصال" (336, 340, 350, 378, 380, 381, 385) vs "بدون إنترنت" (337, 382, 384) | mixed | Two phrasings | Pick one | low |
| 18 | severityNone (223) | لا شيء | Odd for a severity level | لا يوجد | low |
| 19 | proFeatures (85) | ميزات الاحتراف | Possibly unused; "Pro" is a product tier | ميزات Pro | low (may be unused) |
| 20 | Date composition: photoAccessibility (120), scannedLabel (159) | بتاريخ {date}, تم المسح {date} | Reads acceptably in Arabic with اليوم/أمس; shared code item | Code item 5 (shared) | low |


## Symptom Checker review (assets/care/symptoms_ar.json against assets/care/symptoms.json)
Read by hand: 59/59 labels, 41/41 problems (name, what, check, prevent, worry, every step).
Scripted: 329 fields compared; 328 have identical digits and the one difference is correct (English
"1 teaspoon" is written "ملعقة صغيرة", a teaspoon, in powdery_mildew step 4). Every step count matches, no
meaning reversals. Horticultural terminology is strong and correct: تعفن الجذور, الوذمة, البق الدقيقي,
الحشرات القشرية, المنّ, التربس, الذبابة البيضاء, العناكب الحمراء (الحلم), البياض الدقيقي, الندوة العسلية,
الأنثراكنوز, العفن الرمادي, ملح إبسوم. Masculine-singular imperative throughout (consistent).

| # | Where | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| S1 | label leggy | نمو طويل ومستطيل | "مستطيل" means rectangular, not stretched (problem #7 correctly uses "تستطيل") | نمو طويل ومتطاول (or: ممتد) | medium |
| S2 | mealybugs (step 2), scale (step 2) | بعود قطني مبلل بكحول التنظيف | "cleaning alcohol" is not the term for rubbing alcohol; could point to a household product. Same safety point as es/pt | بكحول طبي (إيزوبروبيل 70٪) | medium |
| S3 | old_leaf_drop (prevent), flower_fade (prevent) | لا شيء يُمنع | Reads "nothing is prohibited"; intended "nothing to prevent" | لا شيء يمكن منعه | medium-low |
| S4 | whiteflies (worry) | إذا استمر الإصابة | Gender agreement (الإصابة is feminine) | إذا استمرت الإصابة | low-medium |
| S5 | settling_in (what) | تُسقط النباتات أو تُصفرّ | "تُصفرّ" is a passive form; the verb is intransitive | أو تصفرّ | low |
| S6 | label tap_water | ماء الصنبور عسر أو مكلور | Ungrammatical definiteness | ماء الصنبور العسر أو المكلور | low |
| S7 | label otherwise_healthy | تنمو جيدًا من غير ذلك | Awkward | وفيما عدا ذلك تنمو جيدًا | low |
| S8 | light_change (check) | تغيّر موسم الضوء | Literal "light season" | تغيّر الضوء بتغيّر الفصل | low |
| S9 | Watering nouns: الري (labels, names) vs the verb اسقِ (steps) | mixed | Natural noun/verb pairing; only the interface mixes ري/سقي as nouns (interface finding 9) | none here | info |
