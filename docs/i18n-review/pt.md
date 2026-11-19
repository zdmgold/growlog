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
| 7 | rega (190, 312) | cronograma de rega / sobre rega | "rega" is the European noun; Brazil says "regar" / "irrigação" | cronograma de regas / sobre como regar | low-medium |
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

## Not covered yet
- Symptom Checker labels and problems (assets/care/symptoms_pt.json): not read yet.
