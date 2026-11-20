# Japanese (ja) string review

Read by hand, line by line, against the English text: 437 of 437 interface strings
(`lib/l10n/app_ja.arb`). No helper agents or translation services were used.
Politeness: です・ます throughout, consistent (labels are plain noun/verb forms as usual for UI).
Symptom Checker text: see the end of this file.

## Mechanical checks (scripted)
- 437 keys; 0 missing, 0 extra, 0 empty, 0 placeholder mismatches. Only identical string: GrowLog.
- Plurals: Japanese has no plural, and the 4 plural strings correctly define only "other".
- Punctuation: 0 half-width "?", "!", ":" or "(" next to Japanese text (all full-width). One ASCII
  "..." (index 24) against six "…" (210, 238, 273, 351, 361, 383).
- offProgress (352) is in the CORRECT order ("{done} MB / {total} MB"), unlike Hindi.

## Verdict
No wrong-meaning translations and no broken placeholders. Quality is high and natural
(様子を見ましょう, 今すぐ, 暗めでも育ちます). Findings are terminology consistency and a few precision
issues, with the same two-pass signature as the other languages. Nothing has been changed yet.

## Findings
| # | Key (index) | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| 1 | "care": お手入れ in 9 strings (22, 25, 60, 66, 102, 106, 107, 127, 388) vs お世話 in 19 (140-426) | お手入れスケジュール / お世話の予定 | Two words for the same concept, split by index range (chunk 1 vs the later pass); 388 mixes with 417/418/425 | Unify to お世話 (majority, matches the later screen titles) | medium-low |
| 2 | careTypeTreat (22), treatEvery (66) | 手入れ / 手入れ間隔 | "Treat" (pest/disease treatment) rendered as 手入れ = general care, colliding with "Care" itself | 処置 / 処置間隔 | medium |
| 3 | roomCardAccessibility (119) | 植物{count}個 | Counter 個; the plant counter is 株 (used in 141, 333) | 植物{count}株 | low-medium |
| 4 | aiPrivacyNote (277) | プロバイダ / 当方には届きません | Katakana spelled without the long vowel (276, 278, 279, 289 use プロバイダー); 当方 is stiff for "us" | プロバイダー / GrowLogには届きません | low-medium |
| 5 | speciesLabel (58) | 品種 | 品種 = cultivar/variety; species is 種類 (146, 200) | 種類 (or 学名・種類) | low-medium |
| 6 | addWish (319), wishedOn (321) | 追加 / 追加日：{date} | addWish drops "wish"; wishedOn is identical to addedOn (247) | ウィッシュを追加 / 登録日：{date} | low-medium |
| 7 | Date composition: scannedLabel (159), via scanDateLabel | {name}、{date}にスキャン | With "今日" gives "今日にスキャン" (unnatural) | Code item 5 (shared) | low-medium |
| 8 | phoneDefault (205) | 端末の設定 | Reads "device settings", not "follow the phone's language" | 端末の設定に従う | low-medium |
| 9 | offCareFeed (390) | 約{days}日ごとに肥料 | Elliptic (no verb) and uses 肥料 where the care type is 施肥 (18, 62) | 約{days}日ごとに施肥 | low-medium |
| 10 | Device word: 端末 (9 strings), デバイス (171), スマートフォン (178) | mixed | Three words for the phone | 端末 | low |
| 11 | Free tier: 無料枠 (293) vs 無料プラン (339) | mixed | Two terms | 無料枠 / 無料プラン: pick one | low |
| 12 | Import / clear: インポート (79) vs 読み込み (298); クリア (166) vs 消去 (130, 303, 314) vs 削除 (19 strings) | mixed | Verbs for import and clear differ | Pick one per action | low |
| 13 | MB spacing: "309MB" unspaced (337, 341, 384) vs "{done} MB" spaced (352, 428) | mixed | Inconsistent | Pick one | low |
| 14 | searchHint (24) | 植物を検索... | ASCII three dots; others use … | 植物を検索… | low |
| 15 | markAsDead (33) | 枯れたとしてマーク | Awkward | 枯れた植物としてマーク | low |
| 16 | growthEmpty (267) | 今と後で写真を追加すると | Awkward | 今と、少し後にも写真を追加すると | low |
| 17 | 葉っぱ (177, 215) vs 葉 (112) | mixed | Colloquial vs standard | 葉 | low |
| 18 | doctorTitle (253), doctorCheckHealth (246), offHealthNote (374) | ドクター | Acceptable loan; reads like a person | 植物ドクター (optional) | info |
| 19 | lightLabel (231) | 日当たり | Outdoor-leaning word for indoor light | 光の強さ (optional) | info |
| 20 | Possibly dead strings | proFeatures, upgradeToPro, aiPlantId, cloudSync, journal strings | Not confirmed unused | none | info |


## Symptom Checker review (assets/care/symptoms_ja.json against assets/care/symptoms.json)
Read by hand: 59/59 labels, 41/41 problems (name, what, check, prevent, worry, every step).
Scripted: 329 fields compared; 312 have identical digits. The other 17 were checked BY HAND against the
English: each is an English number word ("a week or two", "four to six weeks", "a couple of weeks",
"a litre", "one leaf", "a month") written as a digit in Japanese, and every quantity matches.
0 real number errors. Every step count matches, no meaning reversals. Terminology is the strongest of
all languages reviewed so far: ハダニ, コナカイガラムシ, カイガラムシ, キノコバエ, アザミウマ,
アブラムシ, コナジラミ, 根詰まり, 葉焼け, 汲み置き, 消毒用アルコール (the correct Japanese term for
rubbing alcohol, so no safety flag here, unlike es/pt/ar), うどんこ病, 灰色かび病, さび病, 炭疽病, すす病.
Note on method: the digit script cannot see a wrong number written as a word on both sides; that is
covered by reading each field, which was done for every language.

| # | Where | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| S1 | label crust; tap_water_burn (check), fertiliser_burn (check, step 3), mineral_crust (name, what, check, step 1), compacted_soil (name 土の固まり) | 白い固まり / 土の固まり | "固まり" = lump/clump; the English is "crust" (a layer) and "compacted". Two different meanings share one word | 白い塩類の皮膜 or 白い付着物 for crust; 土の締まり (or 土の固結) for compacted soil | low-medium |
| S2 | "browning": 茶色化 (mineral_crust worry) vs 褐変 (anthracnose, flower_fade) vs 茶色く... | mixed | Three words for one idea | 褐変 | low |
| S3 | しおれ (kana: 3 + label wilting) vs 萎れ (kanji: 2: flower_fade) | mixed | Inconsistent script | しおれ (or 萎れ) everywhere | low |
| S4 | low_humidity (check) | 乾燥した空気が原因です | Too certain; English says it "signals" dry air | 乾燥した空気のサインです | low |
| S5 | symptom text uses 世話 (4 times, no お); interface uses お手入れ (9) and お世話 (19) | mixed | Same "care" terminology split (interface finding 1) | Resolve with finding 1 (お世話) | low |
| S6 | edema (name) | 浮腫（水ぶくれ） | 浮腫 is the medical term; understood, slightly clinical | エデマ（水ぶくれ症） optional | info |
| S7 | 中性洗剤 (6 times) for "mild liquid soap" | 薄めた中性洗剤 | Standard Japanese household advice; detergent not soap, but safe and conservative | none | info |
| S8 | label tiny_flies | 小さなハエ | Fungus gnats are usually コバエ; label covers gnats and whiteflies, so acceptable | none | info |
