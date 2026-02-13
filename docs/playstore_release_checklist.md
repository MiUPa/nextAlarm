# Play Store Release Checklist (Android)

## 1. Version and Build
- Update `version` in `pubspec.yaml`.
- Rule: every release increments `+buildNumber`.
- Example: `0.1.3+5`.

## 2. Signing
- Confirm `android/key.properties` exists (do not commit this file).
- Required keys:
  - `storeFile`
  - `storePassword`
  - `keyAlias`
  - `keyPassword`
- Confirm keystore file path is valid.

## 3. Local Quality Gate
- Run static analysis:
  - `flutter analyze`
- Optional tests:
  - `flutter test`

## 4. Build Release Artifact
- Recommended command:
  - `./scripts/release_android_playstore.sh`
- Output artifact:
  - `build/app/outputs/bundle/release/app-release.aab`

### CLI Upload (Optional, fully automated)
- Script supports build + upload via CLI:
  - Build only:
    - `./scripts/release_android_playstore.sh build`
  - Upload only (assumes existing build):
    - `PLAY_SERVICE_ACCOUNT_JSON=/path/to/play-service-account.json ./scripts/release_android_playstore.sh upload --track internal`
  - Build and upload in one command:
    - `PLAY_SERVICE_ACCOUNT_JSON=/path/to/play-service-account.json ./scripts/release_android_playstore.sh build-upload --track internal`
  - Promote release between tracks:
    - `PLAY_SERVICE_ACCOUNT_JSON=/path/to/play-service-account.json ./scripts/release_android_playstore.sh promote --from-track internal --to-track production --internal-verified`
- Required:
  - Play service account JSON with `Google Play Android Developer` access for this app.
  - Environment variable:
    - `PLAY_SERVICE_ACCOUNT_JSON`
- Optional:
  - `PLAY_TRACK` to set default track when `--track` is omitted.
  - `--release-status`, `--user-fraction`, `--update-priority`, `--no-commit` for staged rollout control.

## 5. Play Console Metadata
- Prepare:
  - App name / short description / full description
  - Privacy policy URL
  - Screenshots (phone, 7-inch/10-inch tablet if needed)
  - Feature graphic (1024x500)
  - App icon (512x512)
- Existing assets candidate folder:
  - `store_assets/`

## 6. Policy Declarations to Verify
- Exact alarm usage declaration (because app uses alarm permissions).
- Foreground service declaration.
- Microphone declaration (voice challenge feature).
- Data safety form (what data is collected/shared; if none, declare accordingly).

## 7. Internal Testing First
- Upload AAB to `Internal testing` track.
- Add tester emails / group.
- Verify:
  - Alarm fires while app is backgrounded.
  - Lock-screen ringing flow.
  - Notification behavior on Android 13+.
- Gate:
  - Do not publish to `production` until internal real-device verification is complete.
  - CLI policy now requires `--internal-verified` for production promotion.

## 8. Production Release
- Promote tested internal artifact to production.
  - `PLAY_SERVICE_ACCOUNT_JSON=/path/to/play-service-account.json ./scripts/release_android_playstore.sh promote --from-track internal --to-track production --internal-verified`
- Add release notes.
- Roll out staged percentage first (recommended), then 100%.

## Current Project Status (as of this branch)
- Signed AAB build: OK (`build/app/outputs/bundle/release/app-release.aab`).
- Key properties present locally: OK.
- One analyzer error in old widget test was fixed.
