# Portuguese (pt) string review

Read by hand, line by line, against the English text: 437 of 437 interface strings
(`lib/l10n/app_pt.arb`). No helper agents or translation services were used.
Variant: Brazilian Portuguese (aplicativo, Compartilhar, Salvar, Excluir, Configurações, Cômodos).
Symptom Checker text: see the end of this file.

## Mechanical checks (scripted)
- 437 keys; 0 missing, 0 extra, 0 empty, 0 placeholder mismatches.
- Identical to English: GrowLog, Scans, Flash. Valid loanwords or brand names.

## Verdict
No wrong-meaning translations or broken placeholders. Unlike es and de, the voice is CONSISTENT:
você-imperatives throughout ("Toque", "Escaneie", "Adicione"), no tu-forms found. Nothing changed yet.

## Findings
| # | Key (index) | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| 1 | careTypeRepot (20), repotEvery (64), paulStarter4 (310) | Replantar / Replantar a cada / replantá-la | "Replantar" means to replant (re-plant in ground); "repot" is moving to a new pot | Trocar de vaso / Trocar de vaso a cada / trocá-la de vaso | medium |
| 2 | dueNow (191), dueNowCount (192) | Para agora | Literal; and dueToday (255) is "Para hoje" | Pendentes agora / Pendentes agora · {count} | medium |
| 3 | nothingComingUp (195) | Nada por vir | Unnatural | Nada programado | medium |
| 4 | careDueToday (14), careOverdue (15), careDueWithType (16) | "Regar atrasado" | Verb label used as a noun, ungrammatical; same issue as fr/es/de | Needs a code decision (shared) | medium |
| 5 | Date composition: photoAccessibility (120), scannedLabel (159) | "Foto de {date}", "escaneada {date}" | Date text is "Hoje"/"Ontem"/"Há 3 dias"/"7 de out.": gives "escaneada Hoje" | Code item 5 (shared) | medium |
| 6 | celular vs telefone: celular in 277, 419; telefone in 172, 178, 205, 337, 349, 361, 364, 372 | mixed | Two words, same thing (2 vs 8) | Brazil says "celular": unify to celular | low-medium |
| 7 | rega (190, 312) | cronograma de rega / sobre rega | "rega" is used in Brazilian gardening too (18 times in the symptom text); only borderline, more marked in Portugal. CORRECTED: first review overstated this as a European-only noun | optional: regas / como regar | low |
| 8 | lightBrightIndirect (234) | Indireta brilhante | Unnatural | Indireta e forte | low-medium |
| 9 | shareDefaultText (114) | Meu crescimento de planta com o GrowLog | Awkward order | O crescimento da minha planta com o GrowLog | low-medium |
| 10 | Capitalisation: Title Case in 28, 31, 43, 56, 60, 69, 77-79, 85, 87, 94, 98, 101, 102 vs sentence case in 33, 34, 35, 37, 83 | Meu Jardim / Salvar Planta vs Marcar como morta | Inconsistent within the same file; Portuguese uses sentence case | Sentence case everywhere | low (style) |
| 11 | app vs aplicativo: app in 178, 353; aplicativo in 3 | mixed | Two words | Pick one (app is common in Brazil) | low |
| 12 | Possessives: "o seu/a sua" in 139, 140, 167, 417; bare "seu/sua" in 16 other strings | mixed | "o seu jardim" leans European; Brazil usually drops the article | "seu jardim" | low |
| 13 | doctorTitle (253), doctorCheckHealth (246), offHealthNote (374) | Doutor | Reads like a person | Médico das plantas / Doutor das plantas | low |
| 14 | lookingClosely (210) | Olhando de perto… | Literal | Observando com atenção… | low |
| 15 | offErrServer (356) | acessar o servidor direito | Colloquial | acessar o servidor corretamente | low |
| 16 | noSpeciesMatch (417) | digitar o seu | "o seu" has no antecedent | digitar o nome você mesmo | low |
| 17 | offLooksLikeThis (370) | Parece esta | Terse | Parece com esta | low |
| 18 | Possibly dead strings | upgradeToPro, aiPlantId, cloudSync, journal strings | Not confirmed unused | none | info |


## Symptom Checker review (assets/care/symptoms_pt.json against assets/care/symptoms.json)
Read by hand: 59/59 labels, 41/41 problems (name, what, check, prevent, worry, every step).
Scripted: 329 fields compared, every number matches English (cm, minutes, days, deg C, 1 colher de chá
of bicarbonato per litre, 2 cm), every step count matches, no meaning reversals. Voice is consistent
você throughout. Pest and disease terms are correct Brazilian terms: ácaros-aranha, cochonilhas-
farinhentas, cochonilhas de carapaça, tripes, pulgões, moscas-brancas, oídio, fumagina, antracnose,
mofo-cinzento, sal de Epsom.

| # | Where | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| S1 | mealybugs (step 2), scale (step 2) | cotonete embebido em álcool | Plain "álcool" in Brazil can be 46 deg, 70 deg or 96 %; strong concentrations can damage leaves. EN says rubbing alcohol (about 70 %) | cotonete embebido em álcool 70 % (or álcool isopropílico) | medium |
| S2 | "Replantar" used for repotting: 14 times in problem text + label just_repotted ("Foi replantada recentemente") | Replante em um vaso um tamanho maior; Choque do replantio | "replantar" = re-plant; repot is moving to another pot. Also the interface finding 1 | Troque de vaso / Choque da troca de vaso / Teve o vaso trocado recentemente (decide together with interface finding 1) | low-medium |
| S3 | too_little_light (step 3) | Pode as hastes longas... | "Pode" (prune, imperative) also means "can"; ambiguous at sentence start | Faça a poda das hastes longas e sem folhas na primavera... | low-medium |
| S4 | mineral_crust (worry), anthracnose (what, check), flower_fade (what) | escurecendo / escurecimento / escurecem | "browning" rendered as "darkening" (same slight shift as es) | ficando marrons / amarronzamento / ficam marrons | low |
| S5 | label irregular_water | A rega é irregular | Fine; noted for the "rega" note above | optional | info |
| S6 | label wilting | Murchando ou caída | Mixed participle/adjective | Murcha ou caída | low |
| S7 | chewing_pests (what) | mordem furos | Literal "bite holes" | fazem furos | low |
| S8 | light_change (check) | estação de luz | Literal | com a luz da estação | low |
| S9 | label just_moved, loc_even | Mudou de lugar recentemente / Por igual na planta toda | Acceptable | none | info |
