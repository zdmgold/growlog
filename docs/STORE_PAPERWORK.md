# Store paperwork (draft for the Play Console and App Store Connect)

Written from what the app actually does today. Re-check each answer against the
final build before submitting. Nothing here has been entered in either console.

## What the app collects and where it goes

| Data | Collected by | Where it goes | Why |
|---|---|---|---|
| Plants, notes, care logs, reminders, scan history | The app | Stays on the device only | App function |
| Photos (plants and scans) | The app | Stays on the device. A photo leaves only if the user presses a cloud button, and then goes to the AI provider the user picked, using the user's own key | Identification and health checks on request |
| Plant photo processed by the offline model | The app | Never leaves the device | Identification |
| Advertising ID, approximate device and ad interaction data | Google AdMob SDK | Google | Showing ads |
| Purchase status (Remove Ads) | Google Play Billing / Apple StoreKit | The store | Restoring the purchase |
| AI provider key | The app | Encrypted on the device, sent only to the provider the user chose | Cloud features |
| Name, email, account, location, contacts, microphone | Not collected | n/a | n/a |
| Crash or analytics SDKs | None in the app | n/a | n/a |

Model download: the offline model is fetched once from a public GitHub release
(`zdmgold/growlog-models`). The request does not include any user data, but GitHub
sees the device's IP address like any download.

## Google Play: Data safety form

- Does the app collect or share user data? **Yes** (advertising ID by AdMob).
- Is all data encrypted in transit? **Yes** (HTTPS for the model download, AdMob
  and AI providers).
- Can users request that data is deleted? **Yes**: all plant data is on the device.
  Settings has Clear All Data, and uninstalling removes it. The app holds no
  server-side account.
- Data types
  - **Device or other IDs** (advertising ID): collected, shared with a third
    party (Google AdMob), purpose: advertising. Optional? No (ads are shown unless
    the user buys Remove Ads).
  - **Photos**: collected only if the user chooses a cloud AI provider; shared
    with that provider at the user's request; not stored by GrowLog. Declare as
    optional and user-initiated. On-device processing is not "collection".
  - **Purchase history**: handled by Google Play, not GrowLog.
- Ads: **the app contains ads** (AdMob). Interstitials are shown after completing a
  task, never on open or exit.
- Target audience: **not designed for children**. Keep it at 13+ or general
  audience, and do not enrol in Families.
- Ad consent for the EU and UK: you chose to leave the consent step out. Google's
  policy says apps that show ads to users in the EEA, UK and Switzerland need a
  certified consent message. Without it the app may be restricted there. This is
  your decision, and it is recorded here so it is not a surprise.

## Apple: App privacy labels

- **Data used to track you**: Identifiers (advertising identifier) when the user
  allows tracking. The app declares App Tracking Transparency in its plist, but no
  code shows the prompt yet. Decide whether to add it before submission.
- **Data linked to you**: none.
- **Data not linked to you**: Identifiers (device ID via AdMob), Usage Data
  (ad interaction, via AdMob), Photos only if the user sends one to an AI provider
  of their choice.
- Required descriptions in the plist are present for camera, photo library and
  (never used) microphone.
- Minimum iOS version is 16, which the ONNX Runtime plugin requires.

## Listing text

See `ASO_METADATA.md` for the current name, subtitle, short and full description.
Screenshots: see `SCREENSHOT_STRATEGY.md`. The store badges for the website are in
`website/badges/`. Link them only after the listings are live.

## Still needed from you
- Real AdMob app and unit IDs (the build uses Google's test ones).
- Decision on the ad consent message and the iOS tracking prompt.
- Developer account details and the support email shown in the listings.
- Review of the care guide and symptom text before release.
- Confirmation that the model pack may stay on GitHub, or a move to another host.
