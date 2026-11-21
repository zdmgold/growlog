# Korean (ko) string review

Read by hand, line by line, against the English text: 437 of 437 interface strings
(`lib/l10n/app_ko.arb`). No helper agents or translation services were used.
Symptom Checker text: see the end of this file.

## Mechanical checks (scripted)
- 437 keys; 0 missing, 0 extra, 0 empty, 0 placeholder mismatches. Only identical string: GrowLog.
- Plurals: Korean has none; the 4 plural strings correctly define only "other".
- offProgress (352) is in the CORRECT order ("{done}MB / {total}MB"), unlike Hindi.
- Download word is consistently 내려받기 (14 strings, 0 uses of 다운로드). Particles after placeholders are
  hedged "이(가)/을(를)" in 8 strings (standard practice); exactly ONE is not hedged (finding 2).

## Verdict
No wrong-meaning translations and no broken placeholders. Terminology is good (분갈이, 가지치기,
직사광선, 간접광, 내려받기). The main issue is the SPEECH LEVEL, which changes between blocks.
Nothing has been changed yet.

## Findings
| # | Key (index) | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| 1 | Speech level. Formal 합니다체 (60 strings): 2-3, 29-50, 70, 97-108, 124-131, 277, 337-434. Soft 해요체 (56 strings): 136-141, 155-276, 289-329, 385, 399-401. | 불편을 드려 죄송합니다 / 정원이 비어 있어요 | Three blocks in one app: formal (original, and the offline/symptom block), soft (home, scans, plant page, Connect AI). 277 is formal in the middle of the soft block | DECISION: pick one level. My recommendation is 해요체 (a plant-care consumer app; it already covers the home, scan and plant screens). The 60 formal strings would be converted | medium-high |
| 2 | deletePlantMessage (38) | {plantName}과 모든 사진이 영구적으로 삭제됩니다. | The only particle with no hedge: "과" is right only after a consonant; a name like "몬스테라" needs "와" | {plantName}과(와) 모든 사진이... (matches the file's other 8 hedges) or neutral: "{plantName}의 모든 사진과 데이터가 영구적으로 삭제됩니다" | medium |
| 3 | careTypeTreat (22), treatEvery (66) | 관리 / 관리 주기 | "Treat" (pest/disease treatment) is rendered 관리 = care, the same word as "Care" (25, 60, 102, 248 and 27 strings in total) | 치료 / 치료 주기 | medium |
| 4 | waterEvery (61), fertilizeEvery (62) | 물주기 주기 / 비료주기 주기 | The word 주기 is doubled ("watering cycle cycle") | Use 간격 for all six: 물주기 간격, 비료주기 간격, 분무 간격, 분갈이 간격, 가지치기 간격, 치료 간격 | low-medium |
| 5 | speciesLabel (58) vs speciesNotSet (200) | 품종 / 종 | 품종 = cultivar/variety; species is 종 | 종 (선택 사항) | low-medium |
| 6 | addWish (319), wishedOn (321) | 추가 / 추가일: {date} | addWish drops "wish"; wishedOn is identical to addedOn (247) | 위시 추가 / 등록일: {date} | low-medium |
| 7 | Spacing: 물주기 (17, 61, 190, 312), 비료주기 (18, 62) vs 물 주기 (389), 비료 주기 (390) | mixed | Inconsistent spacing of the same word | Pick one | low |
| 8 | statusDue (141) | 오늘 돌봄이 필요한 식물이... | 돌봄 once, 관리 in the other 27 care strings | 관리 | low |
| 9 | searchHint (24) | 식물 검색... | ASCII three dots; six others use … | 식물 검색… | low |
| 10 | cameraNoneFound (171) | 이 기기에서 | 기기 once; 휴대폰 in 10 strings | 이 휴대폰에서 | low |
| 11 | offHealthNote (374) | 식물의 닥터를 사용해 | Awkward | 식물 화면의 닥터로 건강을 점검하세요 | low |
| 12 | Clear/delete: 지우기 (166, 303, 314, 433) vs 삭제 (130 and others) | mixed | Two verbs; some pairs are the same action | Pick one per action | low |
| 13 | greetingAfternoon/Evening (137, 138) | 좋은 오후예요 / 좋은 저녁이에요 | Calque of English greetings; Korean apps usually greet differently | optional | info |
| 14 | Hedged particles 이(가), 을(를): 50, 161, 208, 272, 296, 311, 431, 434 | {name}이(가) | Standard hedge for unknown names; stiff. For 50 the care types all end in a vowel, so "가" is always right | optional | info |
| 15 | Date composition: scannedLabel (159) | {name}, {date} 스캔 | Reads correctly with 오늘 / 어제 / "7월 7일": no problem in Korean | none (the shared code item matters less here) | info |
| 16 | support (84), symptomCheckerTitle (396) | 지원 / 증상 확인기 | 지원 alone is ambiguous; 확인기 is stiff | 고객 지원 / 증상 체크 | low |
| 17 | Possibly dead strings | proFeatures, upgradeToPro, aiPlantId, cloudSync, journal strings | Not confirmed unused | none | info |

## Not covered yet
- Symptom Checker labels and problems (assets/care/symptoms_ko.json): not read yet.
