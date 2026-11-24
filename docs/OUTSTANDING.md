# Outstanding ledger

Items below stay open until the owner closes them. Nothing here has been done.

## Decisions and items that belong to the owner
1. iOS 16 minimum. The ONNX plugin requires it, so iPhones on iOS 15 lose support.
2. iOS tracking prompt. The plist and the privacy page promise it, but no code shows it.
3. Ad consent message. The consent step was rebuilt in Phase 5 (Google's consent form, failure
   handling, Settings "Privacy choices" row) and was only exercised with Google's TEST form on the
   emulator. A live form needs a consent message created in your AdMob account (Privacy and
   messaging) and your real AdMob app ID.
4. Model hosting: GitHub release (today) or Cloudflare R2.
5. iNaturalist terms: BioCLIP 2's training data question.
6. Real AdMob IDs (the build uses Google's test IDs).
7. Play Console: registering the upload key and entering the Data safety form.

## Keyed comparison run (needs a key from the owner)
8. Offline model versus your own AI key. The offline-model run (BioCLIP 2 on the phone) is done first
   in all 10 languages and recorded in docs/i18n-review/README.md. When you supply a free Gemini or
   Groq key, repeat the same run with the key and compare, per language and side by side:
   - identification: species, common name, confidence, health badge;
   - the language the AI actually answers in (the scan prompt asks for the app language; never tested);
   - the Scan result structure and labels, and any English leaking into a translated screen;
   - Doctor end to end (key only; the offline model has no health check, only the Symptom Checker),
     including the entry in the plant's Doctor history and the Scans list;
   - failures, time per scan, free-tier rate limits.
   Doctor (the AI health check) cannot be verified until the key run.

## Work still to do
- Review of the care guide and symptom text; native review of all translations.
- Result caching by image.
- Scan result screen has not been checked at large text sizes.
- Confirm the website deploys on Cloudflare (/terms, new logo and fonts).
- Nothing has run on a phone since the Nov 5 build, and no signed APK has been
  built or installed. No iPhone run has ever happened.
- App Store link for the website badge once a listing exists.
