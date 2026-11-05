# Decisions log (newest last). U = user, A = agent.

## Product
- U: Identity = scan-first. Journal/timeline/measurements dropped; Growth (first vs latest, add photo) + Doctor history replace it.
- U: Offline on-device identification is the foundation; API keys only complement it. A name-search-only fallback is unacceptable.
- U: Bring-your-own-key is a core feature, many providers, simple pick-paste-connect. Pl@ntNet and any shared proxy dropped.
- U: Live in-app camera (gallery kept). Paul becomes a helper button inside results; no "Online" status, no emoji.
- U: Dock = Home, Garden, centre Scan, Schedule, Scans. Settings, language, theme icons in header. Wishlist/Rooms live inside Garden.
- U: Model pack downloads on first use, user chooses Wi-Fi only or mobile data, simple progress. NO RAM limit.
- A (unconfirmed): offline "Save to garden" uses the bundled care guide for schedule defaults.

## Ads / legal
- U: Peshat banner scaffolding on all listed screens; Google test units until release; interstitials only at 3 agreed points; consent flow removed.
- U: Website https://growlog.zdmgold.workers.dev (/privacy, /support), contact stmakarios@gmail.com. Repo website/ files updated; Cloudflare deploy NOT confirmed.

## Technical
- A: Model = BioCLIP 2 image encoder, int8 ONNX, zero-shot against species text embeddings (only candidate passing gates; MIT weights).
- A: Runtime = flutter_onnxruntime 1.9.0 (MIT). Needs iOS 16 -> deployment target raised 15 -> 16.
- A: Pack hosted in public repo zdmgold/growlog-models (main repo will go private). R2 considered, not chosen.
- A: Reminders use inexact scheduling; SCHEDULE_EXACT_ALARM removed (denied by default on Android 14, restricted on Play).
- A: CI init script forces plugin libraries to compileSdk 36 (file_picker pinned 34). pubspec.lock committed.
- A: Release build keeps WorkManager/Room + ONNX classes (R8 crash on launch fixed). Sideload APK built per ABI (arm64 54.7 MB, armv7 44.3, x86_64 62.3).
- A: Taxonomy aliases for Commons data (Calathea->Goeppertia etc.); no iNaturalist or PlantVillage data used.

## Working rules (U)
- Audit first, report findings before changes; smallest fix; no refactors; push to main after approval.
- Do not comment on token safety. Do not ask the user to build or test APKs: test via CI + emulator workflows.
- Existing APK workflow is manual-trigger only. Compile check never builds or uploads an APK.
- User works only from a phone.

## Open decisions (need user)
1. iOS 16 minimum OK?  2. Add ATT prompt on iOS (plist/privacy page mention it; code does not)?
3. Review care guide content.  4. Release signing key (CI-generated vs user-provided).  5. Model hosting: keep GitHub vs Cloudflare R2.
6. Terms of Service URL.  7. BioCLIP 2 training data includes iNaturalist (terms unresolved; user declined legal review).
8. Replace Google test ad IDs with real AdMob IDs.
