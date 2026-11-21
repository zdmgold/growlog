# Chinese (zh, Simplified) string review

Read by hand, line by line, against the English text: 437 of 437 interface strings
(`lib/l10n/app_zh.arb`). No helper agents or translation services were used.
Variant: Simplified Chinese (mainland usage: 应用, 相册, 流量套餐, 点按). Traditional is out of scope by
your earlier decision (any Chinese phone setting shows Simplified).
Symptom Checker text: see the end of this file.

## Mechanical checks (scripted)
- 437 keys; 0 missing, 0 extra, 0 empty, 0 placeholder mismatches. Only identical string: GrowLog.
- Plurals: Chinese has none; the 4 plural strings correctly define only "other".
- Punctuation: 0 half-width "?", "!", ":" or "," next to Chinese text (all full-width). One ASCII "..."
  (index 24) against six "…" (210, 238, 273, 351, 361, 383).
- offProgress (352) is in the CORRECT order ("{done} MB / {total} MB"), unlike Hindi.

## Verdict
No wrong-meaning translations and no broken placeholders. Quality is high and natural (跟随系统,
待办, 耐阴弱光也可, 明亮散射光). The findings are consistency issues with the cleanest two-pass signature
of all the languages: every split below separates exactly at about index 132-139. Nothing changed yet.

## Findings
| # | Key (index) | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| 1 | Register: 您 in 2 strings (3, 30) vs 你 in 20 (139-417) | 很抱歉给您带来不便 / 添加您的第一株植物 vs 你的花园 | Formal and informal address in one app; both 您 strings are in the first block | Convert the 2 to 你: 很抱歉给你带来不便 / 添加你的第一株植物 | medium |
| 2 | "care": 护理 in 8 strings (22, 25, 60, 66, 102, 106, 107, 127), 养护 in 18 (146-426), 照料 in 1 (141) | 需要护理 / 养护计划 / 需要照料 | Three words for one concept. 养护 is the proper plant term; 护理 is nursing/medical | Unify to 养护: 需要养护, 养护计划, 没有即将到来的养护, 记录养护失败 | medium |
| 3 | careTypeTreat (22), treatEvery (66) | 护理 / 护理间隔 | "Treat" (pest/disease control) is the same word as "Care" | 防治 / 防治间隔 (standard horticultural term) | medium |
| 4 | CJK-Latin spacing: NO space in 6 strings (55, 89, 114, 115, 116, 132); a space in 64 (118-436) | AI植物识别 / 由GrowLog追踪 / 2张照片 vs AI 连接设置 | Two typographic conventions in one file; the second pass uses spaces | Use spaces everywhere: AI 植物识别, 由 GrowLog 追踪, GrowLog 备份, 请至少添加 2 张照片 | low-medium |
| 5 | speciesLabel (58), speciesNotSet (200) | 品种 / 未设置品种 | 品种 = cultivar/variety; species is 物种 | 种类 or 物种（可选） / 未设置种类 | low-medium |
| 6 | markAsDead (33) | 标记为已枯萎 | 枯萎 = withered (recoverable), not dead | 标记为已死亡 (or 已枯死) | low-medium |
| 7 | wishedOn (321) | 添加于：{date} | Identical to addedOn (247); loses "wish" | 加入心愿单：{date} | low-medium |
| 8 | confidenceHigh/Medium/Low (216-218) | 置信度高 / 置信度中 / 置信度低 | 置信度 is statistics jargon; "置信度中" reads clipped | 可信度：高 / 中 / 低 | low-medium |
| 9 | offLikely (375) vs symptomPossible (409), symptomMostLikely (408) | 可能 / 有可能 / 最有可能 | "Likely" and "Possible" nearly identical | 375: 较有可能 | low-medium |
| 10 | Tap: 点击 in 30; 点按 in 250, 267, 276, 373, 379, 382 | mixed | Two verbs | 点按 (majority) | low |
| 11 | doctorCheckHealth (246), doctorTitle (253) | 医生 | Reads like a person | 植物医生 | low |
| 12 | offHealthNote (374) | 请用 AI 密钥在该植物上使用医生来做健康检查 | Awkward | 请使用 AI 密钥，在该植物页面用“医生”功能做健康检查 | low |
| 13 | searchHint (24) | 搜索植物... | ASCII three dots; others use … | 搜索植物… | low |
| 14 | Phone: 手机 in 9 strings; 本机 (419); 设备 (171) | mixed | Three words | 手机 | low |
| 15 | statusUpToDate (140) | 你的花园一切就绪 | "all ready" vs "all care done" | 你的花园养护都已完成 | low |
| 16 | Em dash (55, 115) | {plantName}的生长记录 — 由GrowLog追踪 | Chinese uses ——, not a spaced hyphen-dash | ——（no spaces） | low |
| 17 | Date composition: scannedLabel (159) | {name}，扫描于 {date} | Reads acceptably with 今天 / 昨天; no problem in Chinese | none (shared code item matters less) | info |
| 18 | Possibly dead strings | proFeatures, upgradeToPro, aiPlantId, cloudSync, journal strings | Not confirmed unused | none | info |

## Not covered yet
- Symptom Checker labels and problems (assets/care/symptoms_zh.json): not read yet.
