# HANDOFF (read this first)

Repo: https://github.com/zdmgold/growlog (public now; goes private after store submission)  | branch: main | owner: zdmgold
Model pack repo (must stay public): https://github.com/zdmgold/growlog-models (release v1)
Website: https://growlog.zdmgold.workers.dev (/privacy /support) | contact: stmakarios@gmail.com
App id: com.zdmgold.growlog | Flutter 3.47.6 (Dart 3.13) | Android min SDK 24, iOS min 16
Access token: given to the agent in chat (classic PAT, all scopes). NOT stored in the repo (public repo; GitHub auto-revokes committed tokens). Ask the user for it.
Repo secret MODELS_PAT exists (used by Publish Model Pack). User works only from a phone; never ask them to build/test.

## How the agent works here
- Sandbox: no Flutter, no pub.dev; only GitHub reachable. Everything compiles/tests in GitHub Actions. Token can dispatch + cancel runs, push, create repos/secrets. Cannot read job logs: workflows write reports to branches (ci-report*, ci-report-emu-<branch>) read via contents API.
- android/ and ios/ platform files are GENERATED in CI (flutter create); only android/app/* is committed. CI deletes android/app/build.gradle.kts and installs .github/gradle/force-plugin-compilesdk.gradle.
- compile-check.yml: push to main = Android/Dart job (pub get, gen-l10n, analyze, tests, bundle, Kotlin compile, AAR metadata all plugins, R8, no APK). Manual dispatch (any ref) also runs iOS job. Concurrency: a newer run CANCELS older ones.
- Merge pattern: work on a branch, dispatch compile-check on it, then `git push origin <branch>:main` (fast-forward).
- Emulator: emulator-release.yml (manual) installs the latest Build Android x86_64 APK, downloads the model, runs 5 real Commons photos through the gallery picker, saves Aloe, checks the alarm. Reports: branch ci-report-emu-main. Scripts: .github/scripts/emulator_offline.sh + ui_tap.py. emulator-smoke.yml = older generic walk-through (debug build).
- Build Android (build_and_deploy.yml, manual): AAB + per-ABI APKs + symbols. Download from the run's Artifacts. Install app-arm64-v8a-release.apk on phones.

## Where things are (key paths)
lib/services/offline/{offline_model_service,identify_math,preprocess,model_manifest,care_guide}.dart | lib/screens/offline_identify_screen.dart | lib/widgets/{identifier_gate_sheet,connect_ai_card}.dart
lib/utils/scan_launcher.dart (camera gate: model installed OR key) | lib/services/ai/* (BYOK) | lib/services/notification_service.dart | lib/screens/{scan,plant_detail,settings,home}_screen.dart
assets/care/care_guide.json | lib/l10n/app_*.arb (11) | test/*.dart (31 tests) | website/ | docs/{BLUEPRINT,DECISIONS,HANDOFF}.md
bakeoff/{fetch_commons,embed,evaluate,export_onnx,make_pack,bench_ort}.py (+ species.txt with taxonomy aliases, ood.txt); workflows bakeoff.yml, publish-model-pack.yml, arm-bench.yml are manual. NOTE publish-model-pack/arm-bench read artifacts of bake-off run 41249885017 (expire ~Nov 7); rerun bakeoff.yml first.
android/app/{build.gradle,proguard-rules.pro,src/main/AndroidManifest.xml} | codemagic.yaml (iOS build, sets iOS 16) | ios/ExportOptions.plist (YOUR_TEAM_ID placeholder)

## History (batches, all merged to main)
1. Audit + compile fixes for Flutter 3.47 (intl, CardThemeData, l10n, google_mobile_ads 9.x) + compile-check CI.
2. Release config (desugaring, minSdk 24, proguard file, NDK cleanup), APK workflow updated.
3-6. Field Journal theme/fonts/Phosphor; live camera; scan-first home; BYOK Connect AI (8 providers); verification of endpoints.
7-8. Scan flow (species+health+save+Doctor+history); dock, Garden/Schedule/Scans hubs; real test banners; interstitials (3 points).
9. Plant Page redesign, Growth, schedule editor; consent flow removed (user).
10. Paul redesign; Settings/Add Plant/Wishlist/Rooms redesign; motions; website links; iOS fixes (ads, plist, Codemagic); 11-language strings (3 batches).
11. Release fix: plugin compileSdk 36 init script, wider compile check, pubspec.lock.
12. Bake-off (Commons data, 4 models), ONNX int8 export, ARM bench, runtime plugin probe, emulator workflows.
13. Reminder fix (inexact alarms, safe init). Offline model: pack repo, download service, gate sheet, identify screen, home card, Settings row, iOS 16.
14. Translations for offline screens; care guide (107 species) + care card; website rewrite.
15. Launch crash fix (R8 removed WorkManager Room DB) + ONNX keep rules; per-ABI APKs (arm64 54.7 MB).

## Current state (verified in CI/emulator unless noted)
- main compile check green (Android+Dart, 31 tests, 0 analyzer errors); iOS compile green (manual dispatch).
- Build Android on main green; release x86_64 APK runs on emulator: no crash, model downloads (~3 min), 5 photos identified (4/5 right), Save to garden creates reminder (inexact alarm +14d for Aloe), 0 error lines.
- NEVER verified: real phone (arm64) run after the fix, iPhone run, real ads/IAP, RTL layouts, release signing, phone speed/RAM.

## Outstanding (priority order)
1. Confirm arm64 release APK launches on the user's phone (user hit the old crash; fixed in 258d9b4).
2. Release signing (keystore + secrets; android/app/build.gradle already reads GROWLOG_KEYSTORE_PATH env) -- Play needs it.
3. Symptom Checker (offline Doctor) + ~40-problem knowledge base (spec in BLUEPRINT.md); species search in Add Plant.
4. Offline scans into Scans history (ScanRecord has no "health unknown" state yet).
5. Accessibility (48dp targets, 200% text), RTL check, native review of translations + care guide content.
6. Store paperwork: Terms URL, Data Safety form, listings, credits/licence screen (BioCLIP 2 MIT), real AdMob IDs, ATT decision.
7. Confirm website deployed on Cloudflare (repo files updated, deploy unknown).
8. Monstera-type look-alike misses; result cache by image hash; common names only in English.
9. Cleanup: delete throwaway branches (ci-*, feat-*, fix-release) once evidence no longer needed; keep ci-report-* until then.
10. Open decisions: see DECISIONS.md.

## Gotchas
- A green compile check does NOT prove the release app runs (R8 crash proved it): always run emulator-release after changing deps/proguard.
- Dispatching compile-check cancels the in-flight run on main; re-run main after merges.
- uiautomator dumps are flaky; scripts retry and handle ANR dialogs. Do not use `adb root`.
- First launch on a debug build logs a flutter_local_notifications null-context error once (caught; retries on next schedule).
- Commons categories use new taxonomy names (aliases in bakeoff/species.txt). ONNX pack text embeddings are tied to species.json order.


## Update, Nov 9 2026 (latest first)

State of main: Compile Check green (64 tests, 0 analyzer errors).

Done since the last handoff
- Signing: release builds are signed with the upload key from repo secrets
  ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_PASSWORD,
  ANDROID_KEY_ALIAS (alias GrowLog). The Build Android workflow verifies the
  certificate SHA-256 before uploading. Do NOT start Build Android until the owner asks.
  Emulator workflows may be run freely (they build a CI-only APK and upload nothing).
- Offline Symptom Checker: assets/care/symptoms.json (41 problems) with language
  overlays symptoms_<lang>.json for all 10 non-English app languages (machine drafts).
  Engine: lib/services/offline/symptom_checker.dart (ties broken by file order).
  Screen: lib/screens/symptom_checker_screen.dart; entry cards on Scans and Plant Page.
- Species search in Add Plant (care-guide search, fills species, name and schedule).
- Offline scans saved to Scans history (DB v3: scans.source, scans.candidates). Tile
  shows "On this phone"; reopening does not re-run the model. Migration is unit tested.
- Accessibility: 48dp targets (header, tabs, chips, Plant Page buttons, theme
  selector), dock and tab labels shrink to fit at 200% text, Add Plant care rows wrap.
  Checked by .github/workflows/emulator-a11y.yml (reports on branch ci-report-emu-a11y).
  Not yet checked at large text: the scan result screen.
- Store paperwork: website/terms.html, Terms and Licences rows in Settings,
  lib/screens/credits_screen.dart, docs/STORE_PAPERWORK.md, ASO_METADATA.md rewritten
  for the current app, cropped badges in website/badges/ (low resolution; not linked yet).
- Branch cleanup: 15 throwaway code branches deleted. Report branches (ci-report*) kept as evidence.

Still open
- Owner decisions: iOS 16 minimum, iOS tracking prompt, ad consent message, model
  hosting (GitHub vs Cloudflare R2), iNaturalist terms, care-guide and symptom text review.
- Real AdMob IDs; Play Console upload-key registration; Data Safety form and listings entry.
- Website: confirm Cloudflare serves /terms (cannot be reached from the sandbox).
- Native review of all machine-drafted translations; Arabic/Hebrew layout of new screens unseen.
- Nothing has run on a phone since the signed arm64 build (Nov 5); no iPhone run ever.
- Result caching by image (not built).
