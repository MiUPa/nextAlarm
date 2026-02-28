# NextAlarm - Agent Notes

## Project Direction

NextAlarm is a mobile-only alarm app focused on helping heavy sleepers wake up reliably.

- Primary platform: Android
- Secondary platform: iOS shell is present, but reliability work is Android-first
- Explicitly out of scope: Web, browser delivery, GitHub Pages

When making product decisions, prefer:

1. Real alarm reliability over novelty
2. Friction that helps the user wake up
3. Calm, polished UI for a utility app

## Release Checklist

Before merging release-ready changes:

1. Bump `version` in `pubspec.yaml`
2. Run `flutter analyze`
3. Run `flutter test`
4. Build Android release artifact

```bash
flutter build appbundle --release
```

Primary artifact:

`build/app/outputs/bundle/release/app-release.aab`

For Play internal releases, use:

```bash
./scripts/release_android_playstore.sh build-upload --track internal
```

## Current App Shape

### Core user flow

1. User creates one or more alarms
2. Alarm rings into an entry screen
3. User either stops immediately or starts a wake-up challenge
4. Challenge screen enforces the selected wake-up action

### Implemented capabilities

- Unlimited alarms
- Day-of-week repeat rules
- Alarm sound and vibration settings
- Gradual volume
- Wake-up challenges:
  - None
  - Math
  - Voice recognition
  - Shake
  - Steps
- English / Japanese localization
- Android native alarm scheduling and ringing handoff

## Key Files

```text
lib/
  main.dart                               App bootstrap and alarm-stage routing
  models/alarm.dart                       Alarm model and challenge enums
  screens/home_screen.dart                Alarm list and main entry point
  screens/alarm_edit_screen.dart          Alarm creation and editing
  screens/alarm_entry_screen.dart         First-stage ringing screen
  screens/alarm_ringing_screen.dart       Wake-up challenge UI
  services/alarm_service.dart             Alarm state, ringing flow, persistence
  services/android_alarm_platform_service.dart
                                          Android platform channel helpers
  services/app_update_service.dart        Platform-specific app update entry
  services/review_prompt_service.dart     Review prompt timing
  theme/app_theme.dart                    Shared visual tokens

android/
  app/src/main/AndroidManifest.xml        Alarm permissions and Android components
  app/src/main/kotlin/.../alarm/          Native alarm receivers, service, activity

scripts/
  release_android_playstore.sh            Android build/upload helper
```

## Verification Order

Use this order to isolate failures cleanly:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --release
```

Optional on macOS when touching iOS-specific code:

```bash
flutter build ios --no-codesign
```

## Guardrails

- Do not reintroduce Web-only code or browser-specific workflows.
- Do not add Android permissions unless runtime code actively needs them.
- If a change touches alarm reliability, prefer real-device verification over emulator-only confidence.
- Preserve the two-stage ringing flow: entry screen first, challenge screen second.
- Avoid broad dependency churn unless the current version is the direct cause of failure.

## Current Focus Areas

- Alarm reliability across Android OEM variations
- Better diagnostics for missing alarm permissions/settings
- More automated verification around ringing flows
- iOS parity without weakening Android behavior

## Useful References

- `README.md`
- `README.ja.md`
- `docs/playstore_release_checklist.md`
- `docs/android_alarm_reliability_testplan.md`
- `android/app/src/main/play/`
