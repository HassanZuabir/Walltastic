# Play Store Release Checklist — Walltastic

## Done (already in the project)
- [x] Unique application ID: `com.hzstudios.walltastic`
- [x] App icon (adaptive, generated via flutter_launcher_icons)
- [x] Native + custom splash screen
- [x] Privacy policy: in-app (Settings → About → Privacy policy) and hostable
      HTML at `docs/privacy_policy.html`
- [x] Open-source licenses page (Settings → About)
- [x] Release signing wired to `android/key.properties` (falls back to debug
      keys when absent so local release runs still work)
- [x] AdMob integrated with Google test IDs
- [x] Pexels attribution + photographer credits (API guideline compliance)

## Before uploading — you must do these

### 1. Host the privacy policy (required by Play Console)
Upload `docs/privacy_policy.html` somewhere public, e.g. GitHub Pages:
push this repo to GitHub → Settings → Pages → serve from `/docs`.
The URL goes in Play Console → App content → Privacy policy.
Update the contact email in `docs/privacy_policy.html` and
`lib/screens/privacy_policy_screen.dart` if `hzstudios.apps@gmail.com` isn't yours.

### 2. Create your upload keystore
```
keytool -genkey -v -keystore ~/walltastic-upload.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```
Copy `android/key.properties.example` → `android/key.properties` and fill it in.
Back up the keystore — losing it means losing update access (unless you enroll
in Play App Signing, which is recommended and the default).

### 3. Real AdMob IDs
- Create the app + one banner and one interstitial ad unit in the AdMob console.
- Replace the test **app IDs** in:
  - `android/app/src/main/AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`)
  - `ios/Runner/Info.plist` (`GADApplicationIdentifier`)
- Pass real **unit IDs** at build time (see command below).
- Link your AdMob app to the Play Store listing after publishing.

### 4. Pexels API key
Build with your production key via `--dart-define=PEXELS_API_KEY=...`
(debug builds read `lib/config/local_config.dart`, which is gitignored).

### 5. Build the App Bundle
```
flutter build appbundle --release \
  --dart-define=PEXELS_API_KEY=YOUR_KEY \
  --dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-xxx/yyy \
  --dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=ca-app-pub-xxx/zzz
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### 6. Play Console forms (App content section)
- **Privacy policy URL** — from step 1.
- **Ads declaration** — Yes, the app contains ads.
- **Data safety form** — declare:
  - Data collected by third parties (AdMob): Device or other IDs (advertising ID),
    approximate location (IP-based), app interactions — purpose: Advertising.
  - Data is not collected by you; no account; data not sold.
  - Data encrypted in transit: yes. Deletion: uninstall removes all app data.
- **Content rating questionnaire** — wallpaper app, no user-generated content;
  expect Everyone/PEGI 3.
- **Target audience** — 13+ recommended (app shows ads and isn't child-directed).
- **News app / COVID / Government app** — No.

### 7. Store listing assets
- App name (30 chars), short description (80), full description (4000).
- Screenshots: min 2 phone screenshots (16:9 or 9:16, 320–3840 px).
- Feature graphic: 1024 × 500 PNG/JPG (required).
- App icon 512 × 512 (you already have `assets/logo/app_logo.png`).

### 8. Versioning for future updates
Bump `version:` in `pubspec.yaml` (e.g. `1.0.1+2`) — the `+N` build number
must increase with every upload.

## Recommended (not blocking)
- Add a UMP/GDPR consent flow for EU users (Google is increasingly enforcing
  this for AdMob traffic from the EEA).
- Test the release build on a real device before uploading.
- Consider a proxy backend for the Pexels key long-term (keys in shipped
  binaries can be extracted).
