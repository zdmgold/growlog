# Spanish (es) string review

Read by hand, line by line, against the English text: 437 of 437 interface strings
(`lib/l10n/app_es.arb`). No helper agents or translation services were used.
Symptom Checker text: see the section at the end (status line).

## Mechanical checks (scripted)
- 437 keys; 0 missing, 0 extra, 0 empty, 0 placeholder mismatches.
- Identical to English: GrowLog, Flash, Doctor (valid Spanish word). None untranslated.

## Verdict
No wrong-meaning translations or broken placeholders. The main problem is CONSISTENCY: the file
looks like two translation passes with different voices. Nothing has been changed yet.

## Findings
| # | Key (index) | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| 1 | Register, indexes 3, 30, 54, 109, 132 | "Reinicie", "Toque ... su primera planta", "Arrastre", "Agregue" (formal usted) | All 5 formal strings are in the original block (0-132). Everything from index 139 on (about 48 strings) uses informal tú ("Escanea", "Tu jardín", "Toca"). The app talks to the user in two voices. | Convert the 5 to tú: "Reinicia la aplicación o inténtalo de nuevo", "Toca el botón + para agregar tu primera planta", "Arrastra el control...", "Agrega más mediciones...", "Agrega al menos 2 fotos..." | high |
| 2 | Verb choice | "Agregar" in 7 strings (31-132) vs "Añadir/Añade/Añadida" in 18 strings (139-407) | Same action, two verbs. "Agregar" is neutral Latin American, "Añadir" is Spain. | Pick one (decision below) and apply everywhere | high |
| 3 | Photo verbs | "Tomar Foto" (122) vs "Haz una foto" (259, 326), "Hacer otra foto" (368) | Latin America says "tomar una foto"; "hacer una foto" is Spain | Same decision as #2 | medium |
| 4 | rateGrowLog (436) | Valorar GrowLog | "Valorar" is Spain; Latin America says "Calificar" | Same decision as #2 | low |
| 5 | dueNow (191), dueNowCount (192) | Para hoy / Para hoy · {count} | English "Due now" includes overdue items; "Para hoy" is identical to dueToday (255) and misleading | Pendientes ahora / Pendientes · {count} | medium |
| 6 | careOverdue (15), careDueToday (14), careDueWithType (16) | "Regar atrasado", "Regar hoy", "Regar en 3 días" | careType is an infinitive; "Regar atrasado" is ungrammatical | Needs a code decision (noun forms, e.g. Riego) because the same label is also a button | medium |
| 7 | noSchedule (117) | Sin horario | "horario" = timetable; the app says "calendario" everywhere else | Sin calendario | low-medium |
| 8 | lightBrightIndirect (234) | Indirecta brillante | Unnatural | Indirecta e intensa (or: Luz indirecta intensa) | low-medium |
| 9 | offCareTitle (388) | Punto de partida para los cuidados | Singular; English is plural "starting points" | Puntos de partida para los cuidados | low-medium |
| 10 | Date composition: photoAccessibility (120), scannedLabel (159) | "Foto del {date}", "escaneada {date}" | Date text is "Hoy"/"Ayer"/"Hace 3 días"/"7 oct": gives "Foto del Hoy", "escaneada Hoy" | Code item 5 (shared with all languages) | medium |
| 11 | Title Case, e.g. 25, 27, 28, 31, 33-35, 37, 43, 47, 49, 51, 56, 60, 69, 77-79, 82, 85-87, 94, 97, 101 | Mi Jardín, Agregar Planta, Marcar como Muerta, Lista de Deseos | Spanish uses sentence case | Lowercase after the first word | low (style) |
| 12 | hintCheckPricing (294) | Consulta los precios | Other hints are noun phrases ("Pago por uso", "Nivel gratuito disponible") | Consultar precios | low |
| 13 | offErrTimeout (355) | La conexión agotó el tiempo | Literal | Se agotó el tiempo de conexión | low |
| 14 | lookingClosely (210) | Mirando de cerca… | Literal | Observando con atención… | low |
| 15 | noSpeciesMatch (417) | ...escribir la tuya | "la tuya" has no clear antecedent | ...escribir el nombre tú mismo | low |
| 16 | Dead-looking strings | upgradeToPro, aiPlantId, cloudSync, Journal strings | Not confirmed unused | none | info |

## DECISION MADE: Option A, Latin American neutral (Agregar, Tomar una foto, Calificar). Apply in the batch phase.
(Original question, kept for the record; affects #2, #3, #4)
Which Spanish? Option A: Latin American neutral (Agregar, Tomar una foto, Calificar). Option B: Spain
(Añadir, Hacer una foto, Valorar). My default if you do not choose: A, because most Spanish speakers
are in Latin America. Either way the file must use ONE of them. The tú/usted fix (#1) does not depend on it.


## Symptom Checker review (assets/care/symptoms_es.json against assets/care/symptoms.json)
Read by hand: 59/59 labels, 41/41 problems (name, what, check, prevent, worry, every step).
Scripted: 329 fields compared, every number matches English (cm, minutes, days, deg C, 1 teaspoon per
litre, 2 cm), every step count matches, no meaning reversals. Voice is consistent informal tú throughout
this file (it does NOT share the usted/tú split of the interface strings). Cleaner than the French file.

| # | Where | Current | Issue | Suggested | Severity |
|---|---|---|---|---|---|
| S1 | mealybugs (step 2), scale (step 2) | alcohol de limpieza | Not "rubbing alcohol"; could send someone to a household cleaner | alcohol isopropílico (de farmacia) | medium |
| S2 | brown_tips-style wording: mineral_crust (worry), anthracnose (what, check), flower_fade (what) | oscureciéndose / oscurecimiento / se oscurecen | "browning" rendered as "darkening" (slight meaning shift) | poniéndose marrones / pardeamiento / se ponen marrones | low |
| S3 | chewing_pests (name, what) | Plagas masticadoras; muerden agujeros | Literal | Plagas que roen; hacen agujeros | low |
| S4 | underwatering (prevent) | dar sorbitos | Literal "sips" | dar poca agua cada vez | low |
| S5 | old_leaf_drop (check) | ¿Es solo una o dos hojas de abajo | Number agreement | ¿Son solo una o dos hojas de abajo | low |
| S6 | sooty_mould (what, step 2) | melaza | Acceptable horticultural term; "mielato" is more precise | optional | low |
| S7 | label loc_even | Parejo en toda la planta | Latin-American colloquial; neutral is "Uniforme" | Uniforme en toda la planta | low |
| S8 | compacted_soil (step 1) | un palillo | Chopstick; fine | un palillo chino (optional) | info |
