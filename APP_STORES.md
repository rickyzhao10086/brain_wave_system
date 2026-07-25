# App Store Metadata — CerebroSync

Copy-paste ready listing metadata for the Apple App Store and Google Play, derived
from `brainwave_app/`. Every field marked **TODO** needs a real value that does not
exist in the repository yet (URLs, contact details, demo credentials).

Read [Pre-submission blockers](#pre-submission-blockers) before uploading a build.
Several items there will cause a rejection or a failed upload regardless of how
good the listing copy is.

---

## 1. Shared facts

| Field | Value |
| --- | --- |
| App name | CerebroSync |
| Publisher / developer | Coding Minds Academy |
| Version | 1.0.0 (build 1) — `pubspec.yaml:19` |
| Bundle ID (iOS) | `com.ricky.neuromotion` — see blocker B4 |
| Application ID (Android) | `com.ricky.neuromotion` — see blocker B4 |
| Framework | Flutter 3.44.8 (Dart SDK ^3.11.5) |
| Min iOS | 15.0 (`IPHONEOS_DEPLOYMENT_TARGET`) |
| iOS device family | iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) |
| Min Android | API 21 per `flutter_launcher_icons.yaml`; effective value comes from `flutter.minSdkVersion` |
| Backend | Firebase Auth (email/password) + Cloud Firestore, project `cerebrosync-b79a9` |
| Third-party SDKs | `firebase_core`, `firebase_auth`, `cloud_firestore`, `universal_ble`, `url_launcher` |
| Ads / analytics / tracking SDKs | None |
| Hardware required | Muse 2 EEG headband (InterAxon), Bluetooth LE |
| Price | Free (no IAP, no subscriptions) |

**Affiliation statement.** CerebroSync is a Coding Minds Academy project. It has no
affiliation with, endorsement from, or sponsorship by any other organization —
including InterAxon Inc. (maker of Muse), OpenAI, or Google. Keep the disclaimer
line at the end of both descriptions intact; store reviewers treat third-party
hardware brand names in listings as a trademark question, and the disclaimer is
what answers it.

---

## 2. Apple App Store Connect

### 2.1 App Information (version-independent)

| Field | Value |
| --- | --- |
| Name (≤30) | `CerebroSync` |
| Subtitle (≤30) | `Muse 2 EEG session monitor` (26) |
| Primary category | Health & Fitness |
| Secondary category | Education |
| Primary language | English (U.S.) |
| Bundle ID | `com.ricky.neuromotion` |
| Content rights | Contains third-party content: **No** |
| Age rating | **12+** — answer "Medical/Treatment Information: Infrequent/Mild" (the app displays physiological readings and a readiness label). Do not opt into the Kids Category. |
| License agreement | Standard Apple EULA |

### 2.2 Version Information (1.0.0)

**Promotional text** (≤170, editable without review — 163):

```
Connect a Muse 2, watch EEG bands, contact quality, pulse and motion update live,
and keep a minute-by-minute record of every session. Wellness and education only.
```

**Description** (≤4000):

```
CerebroSync turns a Muse 2 headband into a clear, live view of a single session — no laptop, no lab software, and no raw EEG to interpret on your own.

Pair the headband over Bluetooth and the app decodes its sensor packets directly on your phone. You see electrode contact for all four channels, a live EEG trace, relative power across the delta, theta, alpha, beta, and gamma bands, a pulse estimate, breathing pace, and head motion — each labeled plainly so you always know how much to trust the reading in front of you.

WHAT YOU GET
• Direct Bluetooth LE connection to a Muse 2 — no bridge software or desktop app required
• Four EEG channels at 256 Hz: TP9, AF7, AF8, and TP10
• Per-electrode contact quality, so you can fix a poor fit before you record
• Relative band power computed on the phone, in real time
• Pulse and breathing pace estimates from the headband's optical and motion sensors
• Motion and rotation artifact flags, so noisy stretches are obvious
• A three-light session readiness summary: calm, elevated, or review
• Headband battery and stream health at a glance

SESSION HISTORY
Switch on cloud recording and CerebroSync saves a compact checkpoint once a minute — band summaries, contact quality, pulse, and the readiness label — to your private account. Raw EEG never leaves the phone. Switch it off and everything stays local to the device.

BUILT FOR CLARITY
Four tabs, no clutter. Device connects the headband and monitors the stream. Signals shows the evidence behind the current reading. Model explains what the processing pipeline actually does. Setup holds your profile, session notes, and recording preferences.

PRIVACY
Your sessions belong to you. Accounts use email and password, session data is scoped to your account alone, and nothing is sold, shared, or used for advertising.

WHAT YOU NEED
• A Muse 2 headband (sold separately by InterAxon)
• Bluetooth turned on
• An account created in the app

IMPORTANT
CerebroSync is a wellness and education tool, not a medical device. Contact quality, pulse rate, breathing pace, and the calm / elevated / review label are prototype estimates, not clinical measurements or validated classifications. CerebroSync is not intended to diagnose, treat, cure, or prevent any disease or condition, and must not be used to make medical decisions. Speak with a qualified clinician about any health concern.

CerebroSync is developed by Coding Minds Academy. It is not affiliated with, endorsed by, or sponsored by InterAxon Inc., the maker of Muse.
```

**Keywords** (≤100, comma-separated, no spaces — 94):

```
EEG,brainwave,neuro,biofeedback,meditation,focus,alpha,beta,headband,bluetooth,session,mindful
```

> Deliberately omits `muse`. Bidding on a hardware trademark in the keyword field is
> the single most common trigger for a metadata rejection on a compatible-accessory
> app. "Muse 2" appears in the subtitle and description as a factual compatibility
> statement, which is the defensible use.

**What's New in This Version** (1.0.0):

```
First release of CerebroSync.

• Connect a Muse 2 headband directly over Bluetooth LE
• Live EEG trace, four-channel contact quality, and relative band power
• Pulse, breathing pace, and head-motion artifact detection
• Calm / elevated / review session readiness summary
• Optional cloud session history with one checkpoint per minute
```

| Field | Value |
| --- | --- |
| Support URL | `https://codingmind.com` — must match `AppLinks.support` |
| Marketing URL | **TODO** (optional) |
| Privacy Policy URL | Must match `AppLinks.privacyPolicy` — see blocker B3 |
| Copyright | `2026 Coding Minds Academy` |

> Both URLs live in one place in the code:
> `brainwave_app/lib/config/app_links.dart`. The app links out to the privacy
> policy from the login screen and from the delete-account card, and the values
> there must stay identical to what is entered in App Store Connect and the Play
> Console. A URL still carrying a placeholder hides its own link rather than
> shipping a dead button.
| Routing App Coverage File | N/A |

### 2.3 App Privacy (nutrition labels)

Based on what the code actually writes (`lib/services/auth_service.dart`,
`lib/services/firebase_data_service.dart`). No data is used for tracking, so answer
**No** to "Do you or your third-party partners use data for tracking purposes?"

| Data type | Collected | Purpose | Linked to user | Tracking |
| --- | --- | --- | --- | --- |
| Contact Info → Email Address | Yes | App Functionality | Yes | No |
| Contact Info → Name | Yes | App Functionality | Yes | No |
| Health & Fitness → Health | Yes | App Functionality | Yes | No |
| User Content → Other User Content | Yes | App Functionality | Yes | No |
| Identifiers → User ID | Yes | App Functionality | Yes | No |

What maps to each row:

- **Email / Name** — Firebase Auth account and `displayName`.
- **Health** — per-minute session checkpoints: EEG band power summaries, electrode
  contact quality, pulse estimate, breathing pace, motion, and the readiness label.
  Only written while the "Cloud session recording" switch in Setup is on.
- **Other User Content** — the free-text session note field (≤1000 chars).
- **User ID** — Firebase Auth UID, plus the stored preferred Bluetooth device name.

Not collected: precise or coarse location, contacts, photos, browsing history,
purchases, advertising identifiers, crash or performance diagnostics. There is no
Crashlytics or Analytics SDK in `pubspec.lock`, so do not check the Diagnostics
boxes — but re-check this before every submission, because adding
`firebase_analytics` later silently changes the correct answers.

### 2.4 App Review Information

**Demo account** — **TODO**: create a real, email-verified account with a few
completed sessions in its history and put the credentials here. Reviewers cannot
sign up and verify an email address on their own reliably.

**Notes for reviewer** (paste as-is once the credentials are filled in):

```
CerebroSync reads live data from a Muse 2 EEG headband (InterAxon), a third-party Bluetooth LE accessory that we cannot ship to the review team.

NO HARDWARE IS NEEDED TO REVIEW THE APP. After sign-in, the app opens in a simulated-data mode: the Device, Signals, Model, and Setup tabs are fully populated with representative sample values, and the status pill reads "Mock" so the state is never presented as a real measurement. Every screen, the account flow, and the Firestore-backed settings can be reviewed end to end this way.

To exercise the hardware path: on the Device tab, tap "Scan for Muse 2" and accept the Bluetooth permission prompt. The app scans for BLE peripherals advertising a name beginning with "Muse". With no headband nearby the scan ends and the status pill returns to Offline with an on-screen explanation — this is expected, not a crash.

"Connect developer bridge" is an internal debugging path that connects to a local WebSocket at 127.0.0.1:8765. With no bridge running it fails harmlessly and shows an error message.

BLUETOOTH USE: the app connects to the Muse 2 as a BLE peripheral to read its EEG, PPG, accelerometer, gyroscope, and battery telemetry characteristics. Bluetooth is not used for location, proximity, or advertising, which is why the Android manifest declares BLUETOOTH_SCAN with neverForLocation.

ACCOUNT DELETION (Guideline 5.1.1(v)): the Setup tab has a "Delete my account" button at the bottom of the screen. It asks for the account password to confirm, then permanently deletes the Firebase Auth user along with every stored session, checkpoint, and profile record, and returns to the login screen.

MEDICAL CLAIMS: none. CerebroSync is a wellness and education tool. The calm / elevated / review label and all physiological readings are non-clinical prototype estimates, stated as such in the app description and in-app on the Model tab. The app does not diagnose, treat, or recommend treatment.

Demo account: TODO_EMAIL / TODO_PASSWORD
```

**Contact information** — **TODO**: first name, last name, phone, email.

**Attachment** — optional, but a short screen recording of a real Muse 2 session
answers "does the hardware feature work?" before it is ever asked.

### 2.5 Export compliance

The app uses only HTTPS/TLS through the Firebase SDKs — standard, exempt encryption.
Add this to `ios/Runner/Info.plist` so the question stops appearing on every upload:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

### 2.6 Screenshots and assets

| Asset | Requirement |
| --- | --- |
| App icon | 1024×1024 PNG, no alpha, no rounded corners (`assets/icon.png` is the source) |
| iPhone 6.9" | **Required** — 1290×2796 or 1320×2868, 3–10 shots |
| iPad 13" | **Required** because the target ships as iPhone+iPad — 2064×2752 or 2048×2732. To skip this, set `TARGETED_DEVICE_FAMILY = 1` and re-verify the layouts. |
| App Preview video | Optional, 15–30s |

Suggested shot list and captions:

1. **Device tab, live session** — "Connect a Muse 2 in one tap"
2. **Contact quality card** — "Fix a poor fit before you record"
3. **Signals tab, readiness gauge** — "Calm, elevated, or worth a review"
4. **EEG band power breakdown** — "Delta to gamma, computed on your phone"
5. **Body signals card** — "Pulse, breathing, and motion artifacts"
6. **Setup tab** — "Cloud recording stays under your control"

---

## 3. Google Play Console

### 3.1 Store listing

| Field | Value |
| --- | --- |
| App name (≤30) | `CerebroSync: Muse 2 EEG` (23) |
| Short description (≤80) | `Live EEG, pulse, and motion from your Muse 2 headband, with session history.` (76) |

**Full description** (≤4000): reuse the App Store description in §2.2 verbatim. It
is within length and already carries the medical disclaimer and the affiliation
statement, both of which Play's Health apps policy expects to be visible in the
listing rather than only in-app.

| Field | Value |
| --- | --- |
| App category | Health & Fitness |
| Tags | Health & Fitness, Meditation, Personal wellness |
| Email address | **TODO** — public, required |
| Website | `https://codingmind.com` (optional) |
| Phone | **TODO** (optional) |
| Privacy Policy URL | Must match `AppLinks.privacyPolicy` — see blocker B3 |
| Contains ads | No |
| In-app purchases | No |

**Release notes** (≤500 chars):

```
First release of CerebroSync.

• Connect a Muse 2 headband directly over Bluetooth LE
• Live EEG trace, four-channel contact quality, and relative band power
• Pulse, breathing pace, and head-motion artifact detection
• Calm / elevated / review session readiness summary
• Optional cloud session history with one checkpoint per minute
```

### 3.2 Graphic assets

| Asset | Requirement |
| --- | --- |
| App icon | 512×512 PNG, 32-bit with alpha, ≤1 MB |
| Feature graphic | **Required** — 1024×500 PNG/JPEG, no alpha |
| Phone screenshots | 2–8, 16:9 or 9:16, each side 320–3840 px |
| 7" / 10" tablet screenshots | Only if you declare tablet support |
| Promo video | Optional YouTube URL |

The feature graphic is the asset most likely to be missing at submission time —
nothing in the repo generates one.

### 3.3 Data safety form

Mirrors §2.3. Declare:

- **Is all user data encrypted in transit?** Yes (Firestore and Firebase Auth use TLS).
- **Do you provide a way to request data deletion?** Yes — Setup tab → "Delete account"
  removes the account and all stored session data in one step (B2).

| Data type | Collected | Shared | Optional? | Purpose |
| --- | --- | --- | --- | --- |
| Personal info → Name | Yes | No | Required | Account management, App functionality |
| Personal info → Email address | Yes | No | Required | Account management, App functionality |
| Personal info → User IDs | Yes | No | Required | Account management, App functionality |
| Health and fitness → Health info | Yes | No | **Optional** (Setup toggle) | App functionality |
| App activity → Other user-generated content | Yes | No | Optional | App functionality |

Nothing is shared with third parties. Firebase is a processor here, not a recipient —
Play does not count your own backend as "sharing."

### 3.4 Content rating questionnaire (IARC)

Category: Utility, Productivity, Communication or Other. Answer No to violence,
sexual content, profanity, controlled substances, gambling, user-to-user
communication, location sharing, and digital purchases. Answer Yes to "collects
personal information" (accounts, health data) and No to sharing it with third
parties. Expected outcome: **Everyone / PEGI 3**, with a data-collection note
attached.

### 3.5 Additional declarations

- **Target audience and content** — select 13+ only. Selecting any under-13 bracket
  triggers Families policy and a COPPA review the app is not built for.
- **Health apps declaration** — required for the Health & Fitness category. Declare:
  not a medical device, no clinical or diagnostic claims, no regulatory clearance
  sought or held, wellness and education use only, no prescription or treatment
  recommendations, no Health Connect integration.
- **Advertising ID** — no ads SDK, so do not declare the `AD_ID` permission.
- **Permissions** — `BLUETOOTH_SCAN` is declared with `neverForLocation`, so no
  location declaration should be needed. `ACCESS_FINE_LOCATION` /
  `ACCESS_COARSE_LOCATION` are present with `maxSdkVersion` caps for legacy devices
  (`AndroidManifest.xml:6-7`); if the Console still surfaces the Location permission
  declaration form, answer that location is not used at runtime and the capped
  entries exist only for pre-API-31 BLE scanning.
- **App access** — reviewers need a login. Provide the same demo credentials as §2.4
  under "All functionality in my app is restricted."
- **Government apps / financial features / news** — No to all.
- **Data deletion** — supply a deletion request URL alongside the in-app path (B2).

---

## Pre-submission blockers

These are real, verified issues in the current tree. Each one blocks a submission
or an upload on its own.

**B1 — Android release builds are signed with the debug keystore.**
`brainwave_app/android/app/build.gradle.kts:40` still has the Flutter template's
`signingConfig = signingConfigs.getByName("debug")`. Play rejects any artifact signed
with a debug key. Create an upload keystore, wire a `signingConfigs.release` block
from a gitignored `key.properties`, and enroll in Play App Signing.

**B2 — In-app account deletion. ✅ Implemented.**
Setup tab → "Delete account". `AuthService.deleteAccount` re-authenticates with the
user's password, then `FirebaseDataService.deleteAccountData` erases every session,
every sample, and the profile document, and only then is the Firebase Auth user
deleted. Answer **Yes** to both stores' account- and data-deletion questions, and
point the Play "data deletion" field at the in-app path.

**B3 — The privacy policy URL points at a different app's policy.**
`brainwave_app/lib/config/app_links.dart` currently holds a flycricket-hosted policy
for **"Skate Sensor" by "Jocelyn"** (contact `z.joce.0204@gmail.com`). It covers only
IP address, pages visited, timestamps, OS, and device location — it does not mention
EEG or health data, Bluetooth, Firebase, accounts, or deletion. Submitting it would
misdescribe what CerebroSync actually collects, and the app name mismatch is visible
in the URL slug itself. Both stores treat that as a rejection, and a privacy
declaration that contradicts the app's behavior is a misrepresentation rather than a
formatting error. Publish a CerebroSync policy that names Coding Minds Academy,
describes the EEG-derived session data in Firestore, names Firebase as the processor,
and documents the deletion path from B2 — then update the constant.

**B4 — Bundle identifier: keeping `com.ricky.neuromotion`. ✅ Decided.**
The app is CerebroSync and the repo is NeuroMotion, but both platform identifiers stay
`com.ricky.neuromotion` (`build.gradle.kts:12,27` and the iOS `PRODUCT_BUNDLE_IDENTIFIER`).
This is invisible to users — it appears only in the Play Store URL and in App Store
Connect — and it is permanent once the first build is uploaded.

**B5 — Reviewers have no Muse 2.**
Apple Guideline 2.1 rejects apps whose core feature cannot be exercised. The mitigation
is already in the code — the app boots into mock mode (`MuseLiveService` defaults to
`MuseConnectionStatus.mock` with `MuseSnapshot.mock()`), so all four tabs are populated
without hardware. The review notes in §2.4 spell this out. Verify before submitting that
a fresh install with Bluetooth off still renders every tab and never dead-ends.

**B6 — Verify the Android target API level.**
`targetSdk` inherits from `flutter.targetSdkVersion` (`build.gradle.kts:31`). Play
enforces a minimum target API for new apps that rises every August. Confirm the
resolved value against Play's current requirement with
`cd brainwave_app/android && ./gradlew :app:properties | grep -i targetSdk`, and pin it
explicitly if it falls short.

**B7 — Placeholder package description.**
`pubspec.yaml:2` still reads `"A new Flutter project."`. It never reaches a store
listing, but it is the kind of leftover that reads as an unfinished submission if a
reviewer sees the source. Replace it with a real one-line description.

### Also worth doing before launch

- Add a visible in-app disclaimer. Today the "non-clinical" wording lives in body copy
  on the Model tab; a persistent line under the readiness gauge on the Signals tab is
  what health-app reviewers look for, since that gauge is the screen most likely to be
  read as a medical result.
- Enable Firebase App Check (App Attest / DeviceCheck on iOS, Play Integrity on
  Android) before public release, as `brainwave_app/README.md` already recommends.
- Confirm the iPad layouts hold at 13", or drop iPad from `TARGETED_DEVICE_FAMILY`.
- Re-verify the §2.3 and §3.3 answers on every release. Adding Analytics, Crashlytics,
  or the OpenAI call sketched on the Model tab changes the correct answers, and a stale
  privacy declaration is treated as a misrepresentation rather than an oversight.
