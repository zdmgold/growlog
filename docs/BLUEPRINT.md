# GrowLog blueprint (v3, current as of the last commit on main)

Product: scan a plant -> know what it is -> save it -> get care reminders. Works offline, no account, no key required.
Your own AI key (BYOK) is an optional upgrade (health check, second opinion, chat). Flutter app, Android + iOS.

## Principles
1. Core loop works offline (scan, identify, save, care guide, reminders).
2. Never guess silently: show confidence, top-3 cards, "I'm not sure".
3. Wrong care advice is worse than none: care shown as general starting points.
4. Photos stay on the phone unless the user starts a cloud action.
5. Every quality claim is measured in CI before it is shown.
6. No extras nobody asked for.

## Architecture (3 tiers)
- A. Offline core (built): BioCLIP 2 int8 ONNX image encoder + precomputed species text embeddings (zero-shot), bundled care guide.
- B. Optional on-device LLM (Gemma, 2.4-3.1 GB): NOT built, not planned soon.
- C. Cloud with user's own key (built): Anthropic, OpenAI, Gemini, xAI, Mistral, Groq, OpenRouter, Cerebras. Live model discovery + vision test on connect.

Identify flow: preprocess (center-crop, 224, CLIP mean/std) -> embedding -> cosine vs 107 species -> softmax(100x).
accept_cosine 0.687 (reject below = "not sure"), confident_prob 0.64 (>= shows "Looks like this"). Values in model_manifest.json.

## Model pack (hosted outside the main repo)
Public repo `zdmgold/growlog-models`, release `v1`: bioclip2_image_int8.onnx (~309 MB), text_embeddings_fp16.bin, species.json, model_manifest.json (sizes + SHA-256), NOTICE.md.
App downloads on first use (Wi-Fi only or mobile data), resumable, checksum-verified. Built by workflow `Publish Model Pack` + bakeoff/make_pack.py.

## Evidence (bake-off, 106 species, 528 photos, Commons images = optimistic)
| model | top-1 | top-3 | OOD accepted |
|---|---|---|---|
| BioCLIP 2 zero-shot | 76.3% | 88.4% | 3.6% |
| BioCLIP 2 int8 (shipped) | 74.8% | 87.5% | 3.6% |
| BioCLIP v1 | 67.8% | 79.0% | 14.9% |
| DINOv2-small trained | 64.6% | 79.2% | 48.8% |
| CLIP | 28.0% | 47.2% | 35.1% |
Gates: top-3 >= 85%, OOD accepted <= 30%. In-app emulator test (release build): 4 of 5 real photos right (Monstera missed top-3).
ARM server core, int8: 853 ms (1 thread) / 234 ms (4 threads), ~610 MB RAM. Phone speed unmeasured.

## Screens
Home (scan card, Today's care, recent scans, My garden) | Garden hub (Plants/Wishlist/Rooms) | Schedule (Due now/Upcoming/All) | Scans history | Plant Page (care rows, schedule editor, Growth, Doctor history) | Camera (live in-app) | Scan result (cloud) | Offline result (top-3 cards, care card, save) | Add Plant | Settings | Connect AI | Paul chat | Identifier gate sheet.
Dock: Home, Garden, centre Scan, Schedule, Scans. Header: language, theme, settings. Banner ad below dock (Peshat scaffold: 320x50, 32dp gap above, 4dp below).

## Design system "Field Journal"
Paper #F6F1E7, ink #1F3A2D, green #4CAF50-family, terracotta #C8643C (attention), amber #E0A33A (watch). Dark "night greenhouse" #0E1A14. Fraunces (serif, names) + Inter, bundled. Phosphor icons (subset font). Motions: health ring, slide-up, leaf unfurl, watering drop (respect reduce-motion).

## Ads / money
Google TEST units only (swap for real IDs before release). Banners: Home, Garden, Schedule, Scans, Plant Page, scan result, Add Plant, Settings. None on camera. Interstitials at 3 points (after Save to garden, leaving a fresh scan result, after manual add); none before 3rd task, then max 1 per 5 min, 3 per session. Remove Ads IAP (never run on a device). No consent flow (user removed it; EU/UK policy exposure).

## Care guide
assets/care/care_guide.json: 107 species -> common name, light level, water days, feed days (Lithops: none). Authored by the agent from general knowledge; NEEDS HUMAN REVIEW. No toxicity data on purpose.

## Languages
11: en es fr de pt ar hi ja ko zh he. New strings are machine drafts (need native review; RTL unseen on screen). Test keeps ARB key parity.

## Phases
| Phase | Scope | Status |
|---|---|---|
| P1 | Redesign, voice, motions, Phosphor, strings in 11 languages | DONE |
| P2 | Care guide (done), Symptom Checker (todo), species search in Add Plant (todo) | PARTIAL |
| P3 | Offline identifier (BioCLIP 2 int8) + CI bake-off + download pack | DONE |
| P4 | Photo symptom model, optional Gemma | NOT STARTED (likely cloud-only) |
| P5 | Hardening: signing, perf, accessibility, store paperwork, device tests | NOT STARTED |

## Symptom Checker spec (todo)
Guided: where (leaves/stems/roots+soil/whole/flowers) -> what (yellowing, brown tips, spots, wilting, white powder, sticky, webbing, insects, holes, leggy, curling, mushy base, no growth) -> pattern (old/new, edges/centre, patchy/even) -> context (watering, light, recent move/repot, last feed). Scoring ranks top-3 causes with first steps, prevention, "when to worry". ~40 problems: water (over/under/inconsistent, root rot, edema, tap-water burn, low humidity), light, temperature, nutrition (N, Mg, Fe deficiency, fertiliser burn), pot/soil (root-bound, compaction, drainage, crust), pests (spider mites, mealybugs, scale, fungus gnats, thrips, aphids, whiteflies), diseases (powdery mildew, fungal/bacterial leaf spot, grey mould, rust, anthracnose, stem rot, sooty mould), normal processes (old leaf drop, dormancy, repot shock, settling in, flower fade). Conservative treatments only. Content needs human review.
