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
| 3 | careTypeTreat (22), treatEvery (66) | 护理 / 护理间隔 | "Treat" (pest/disease control) is the same word as "Care" | 防治 / 防治间隔 (clearest for a plant-care user). Option: 处理 / 处理间隔 matches the Symptom Checker, which says 处理 15 times and 防治 once. Default if you do not choose: 防治 | medium |
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


## Symptom Checker review (assets/care/symptoms_zh.json against assets/care/symptoms.json)
Read by hand: 59/59 labels, 41/41 problems (name, what, check, prevent, worry, every step).
Scripted: 329 fields compared, 0 digit mismatches. Chinese writes some quantities in hanzi on both
sides, which a digit check cannot see, so those were read by hand against the English: 一两周, 一到两周,
一到两年, 四到六周, 三到四次, 两个月, 六周, 两周, 一个月, 一升, 一周, 一两片, 六个月 (label) all match.
Every step count matches, no meaning reversals. Terminology is excellent: 烂根, 木栓化, 水肿, 徒长,
萎蔫, 板结, 穿堂风, 高温胁迫, 肥害 (exact term for fertiliser burn), 螯合铁, 泻盐 (Epsom salt), 红蜘蛛
（叶螨）, 粉蚧, 介壳虫, 蕈蚊, 蓟马, 蚜虫, 粉虱, 白粉病, 灰霉病, 锈病, 炭疽病, 煤污病, 蜜露, 晕圈.
The file already uses 养护 (4) and 你 (2), never 护理 or 您, which supports interface findings 1 and 2.
"消毒酒精" is a clear household term, so there is no safety flag (unlike es/pt/ar).

| # | Where | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| S1 | poor_drainage (step 1) | 把养殖盆放进装饰盆里 | 养殖 = raising animals / aquaculture; wrong domain for a plant pot | 把种植盆（栽培盆）放进装饰盆里 | medium |
| S2 | underwatering (worry), heat_stress (worry) | 叶片仍然干脆 | 干脆 normally means "decisive/simply"; the intended "crisp" is 干枯发脆 (low_humidity check already says 变脆 correctly) | 叶片仍然干枯发脆 | low-medium |
| S3 | repot_shock (name) | 换盆休克 | Literal "repot shock"; 休克 is the medical term for shock | 换盆后缓苗 (the horticultural term) | low-medium |
| S4 | whiteflies (name) | 粉虱（白飞虱） | 白飞虱 is also the name of a rice pest | 粉虱（烟粉虱） or just 粉虱 | low |
| S5 | label sticky | 黏糊糊的残留物 | Colloquial; fine | 黏性残留物 (optional) | info |
| S6 | 处理 for "treat" (15 uses) vs the interface careTypeTreat | mixed | See interface finding 3 | decide with finding 3 | low-medium |
