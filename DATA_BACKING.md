# Data Safety / Privacy Nutrition Label Reference

Keep this in sync with actual app behavior — update the moment any
data-collecting feature changes, per Apple 5.1.2 / Play's Data Safety
policy. This is a reference for filling out App Store Connect's
Privacy Nutrition Label and Play Console's Data Safety form; it is not
itself submitted anywhere.

## Data collected

| Data type | Collected? | Linked to user? | Used for | Where it lives |
|---|---|---|---|---|
| Photos | No collection — stored locally only | N/A | Growth timeline | Device only, never uploaded |
| Plant care logs | No collection — stored locally only | N/A | Reminders, history | Device only (sqflite) |
| Advertising ID | Yes, via AdMob | Not linked to identity | Ad personalization | Google AdMob |
| Purchase history | Yes, via App Store/Play Billing | Linked to store account, not GrowLog | Restore "Remove Ads" | Apple/Google, not GrowLog's servers |

## What GrowLog does NOT collect
- No account/email/name
- No location data
- No contacts
- No health data
- No analytics SDK (none integrated as of this build)

## Answers for Apple's Privacy Nutrition Label
- "Data Not Collected" applies to all app-generated content (plants, photos, care logs).
- "Data Linked to You": none.
- "Data Used to Track You": Advertising ID (via AdMob), disclosed via the ATT prompt.

## Answers for Play Console's Data Safety form
- Declare AD_ID permission (already in AndroidManifest.xml).
- "Does your app collect or share any of the required user data types?" → Yes: Advertising ID only, for advertising purposes, not required for app functionality (ads can be avoided via Remove Ads purchase).
- All other categories: No.
