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

## Codex Operating Defaults

- For non-trivial work, anchor execution around four points: Goal, Context, Constraints, Done.
- Keep durable agent guidance in this file. If the same mistake or clarification repeats, update `AGENTS.md` instead of relying on one-off prompts.
- Keep permissions tight by default. Prefer workspace-local reads, edits, and routine commands; escalate only when a required step truly exceeds the sandbox.
- Do not stop at code generation alone. Prefer the smallest relevant verification step first, then expand to broader checks when the risk justifies it.
- If a workflow becomes repetitive and stable, codify it in `scripts/` or `skills/` instead of repeating ad hoc command sequences.

## Language-Specific Guidance

### Dart / Flutter

- Preserve the existing split between models, services, screens, and theme. Do not introduce a new state-management approach when `provider` and the current service layer are sufficient.
- Route user-facing copy through localization where applicable. Avoid hardcoded UI strings in Dart when `AppLocalizations` should own them.
- Reuse `AppTheme` and existing visual tokens before adding new styling primitives.
- Keep alarm-stage behavior explicit. Changes around ringing must preserve entry-screen-first and challenge-screen-second routing.
- Prefer focused edits over large refactors in reliability-sensitive code such as `alarm_service.dart` and alarm-related screens.

### Kotlin / Android

- Treat `android/app/src/main/kotlin/.../alarm/` as reliability-critical code. Preserve exact-alarm, foreground-service, wake-lock, notification, and full-screen intent behavior unless the change clearly improves reliability.
- Keep Dart/native contracts aligned. If alarm payload fields, enum indexes, intent extras, or platform-channel method names change, update both sides in the same task.
- Add permissions, exported components, or background behaviors only when runtime code actively needs them and the manifest/service change is justified.
- Prefer safe fallbacks and targeted diagnostics over broad rewrites in alarm scheduling and ringing code.

### Shell / Release Scripts

- Keep shell scripts strict and explicit: `set -euo pipefail`, validated env vars, and repo-root-relative paths.
- Fail fast on signing, service-account, and artifact preconditions. Do not silently weaken release guardrails.
- Preserve the internal-first Play release policy unless the user explicitly requests a policy change.

### Markdown / Localization

- `README.md` is the canonical project overview. Keep `README.ja.md` aligned when setup steps, product scope, or user-visible behavior changes.
- When behavior changes, update the nearest relevant doc or release note instead of leaving the operational impact implicit.
- Prefer concrete commands, artifact paths, and platform-specific notes over generic prose.

## Verification by Change Type

- Dart UI or service changes: run `flutter analyze` and the narrowest relevant `flutter test`.
- Native Android alarm changes: run `flutter analyze`, `flutter test`, and `flutter build apk --debug`; prefer physical-device checks using `docs/android_alarm_reliability_testplan.md`.
- Release script changes: exercise the narrowest safe path that proves the modified logic, while keeping `build/app/outputs/bundle/release/app-release.aab` as the expected release artifact.
- Docs-only changes: review for consistency and command accuracy; no app build is required.

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
