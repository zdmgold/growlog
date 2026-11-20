# Hindi (hi) string review

Read by hand, line by line, against the English text: 437 of 437 interface strings
(`lib/l10n/app_hi.arb`). No helper agents or translation services were used.
Voice: formal "आप" with "-ें" imperatives throughout (consistent, no register split).
Symptom Checker text: see the end of this file.

## Mechanical checks (scripted)
- 437 keys; 0 missing, 0 extra, 0 empty, 0 placeholder mismatches. Only identical string: GrowLog.
- Plural blocks: Hindi has only one/other, so the =1/other blocks are structurally correct
  (no Arabic-style problem). 11 plural strings checked.

## Verdict
One genuine meaning error (finding 1), one ambiguity (2), plus the same "two translation passes"
signature seen in es/de/ar (spelling and terminology split between index 0-132 and 133+).
Nothing has been changed yet.

## Findings
| # | Key (index) | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| 1 | offProgress (352) | {done} MB में से {total} MB · {pct}% | REVERSED. "X में से Y" = "Y out of X", so it reads "{total} out of {done}" (e.g. "309 MB out of 100 MB") | {total} MB में से {done} MB · {pct}% | high |
| 2 | yesterday (5), tomorrow (12) | कल / कल | "कल" means both yesterday and tomorrow; two different strings with identical text | yesterday: बीता कल; tomorrow: आने वाला कल (or: कल, for tomorrow only) | medium-high |
| 3 | waterEvery..treatEvery (61-66) + daysSuffix (67) | हर इतने दिनों में पानी दें [N] दिन | "every so-many days" followed by a number field and "दिन" is redundant; the English "Water every [N] days" order does not carry into Hindi (verb last) | Rename the labels to noun phrases: पानी देने का अंतराल / खाद देने का अंतराल / छिड़काव का अंतराल / गमला बदलने का अंतराल / छंटाई का अंतराल / उपचार का अंतराल, keep "दिन" | medium |
| 4 | Spelling: anusvara "-ाएं" in 8 strings (30, 36, 37, 38, 76, 85, 97, 101); chandrabindu "-ाएँ" in 13 (143-387); also ऊंचाई (111) | दबाएं / हटाएं vs जाएँ / हटाएँ | Two spelling conventions in one file (same action even differs: 36 "हटाएं" vs 160 "हटाएँ") | Use chandrabindu (ँ) everywhere (majority, standard): दबाएँ, हटाएँ, सूचनाएँ, ऊँचाई | medium-low |
| 5 | "Schedule": अनुसूची in 42, 60, 102, 117; शेड्यूल in 190, 197, 245, 249, 250; कार्यक्रम in 418 | three terms | One concept, three words | Unify to शेड्यूल (matches the buttons the person taps: 245, 249) | medium-low |
| 6 | paulStarter4 (310) | इसे कब गमले में बदलना चाहिए? | "गमले में बदलना" = "change it into a pot", not repot | इसका गमला कब बदलना चाहिए? | medium-low |
| 7 | greetingAfternoon (137) | नमस्कार | Generic greeting, not "Good afternoon" | शुभ दोपहर | low-medium |
| 8 | Growth: वृद्धि in 8 strings, विकास in 252 | वृद्धि / विकास | विकास = development; mixed | वृद्धि | low-medium |
| 9 | addToWishlist (318) | विशलिस्ट में जोड़ें | Transliteration; the rest use इच्छा सूची (43, 98, 100) | इच्छा सूची में जोड़ें | low-medium |
| 10 | Date composition: scannedLabel (159) | {name}, {date} को स्कैन किया | with "आज" gives "आज को स्कैन किया" (ungrammatical) | Code item 5 (shared) | medium |
| 11 | hintFreeTier (293) vs offUseKeySub (339) | मुफ़्त स्तर उपलब्ध / मुफ़्त प्लान | Same concept, two terms; "स्तर" is a literal tier | मुफ़्त प्लान उपलब्ध | low-medium |
| 12 | aiConnectedTo (153), settingsAiConnected (302) | AI कनेक्ट · {provider} | "कनेक्ट" is the verb stem | AI कनेक्टेड · {provider} / AI से जुड़ा: {provider} | low-medium |
| 13 | Import/restore: आयात (79) vs इम्पोर्ट (298); पुनर्स्थापित (87) vs बहाल (300) | mixed | Pairs of terms for the same action | आयात / पुनर्स्थापित everywhere | low |
| 14 | aiPlantId (89) | एआई | 15 other strings write Latin "AI" | AI | low |
| 15 | helpSupport (305) | सहायता और सपोर्ट | Redundant (both mean support) | सहायता | low |
| 16 | symptomCheckerTitle (396), creditsGuideBody (426) | लक्षण जाँचकर्ता | "जाँचकर्ता" = a person who checks | लक्षण जाँच | low |
| 17 | monthsAgo (8) | 1 महीने पहले | Singular form | 1 महीना पहले | low |
| 18 | nothingComingUp (195) | कुछ भी आने वाला नहीं | Literal | कुछ भी निर्धारित नहीं | low |
| 19 | confidenceHigh/Medium/Low (216-218) | उच्च/मध्यम/कम विश्वास | "विश्वास" = belief/trust | उच्च/मध्यम/कम भरोसा | low |
| 20 | Possibly dead strings | proFeatures, upgradeToPro, aiPlantId, cloudSync, journal strings | Not confirmed unused | none | info |

## Not covered yet
- Symptom Checker labels and problems (assets/care/symptoms_hi.json): not read yet.
