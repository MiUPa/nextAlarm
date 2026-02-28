---
name: nextalarm-cross-platform-build-fix
description: Diagnose and fix build or compatibility regressions in the mobile NextAlarm app, with Android-first verification and optional iOS checks.
---

# Goal

Resolve build failures quickly while preserving behavior on the mobile app targets.

## Use Bundled Resources

- Read `references/build-check-order.md` for command order.
- Read `references/known-issues.md` for recurring failure patterns.
- Run `scripts/build_probe.sh` to reproduce failures consistently.

## Core Files

Start with these files unless logs point elsewhere:

- `pubspec.yaml`
- `android/build.gradle.kts`
- `android/settings.gradle.kts`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Podfile`
- `ios/Runner/Info.plist`
- `lib/main.dart`
- `lib/services/alarm_service.dart`
- `lib/services/android_alarm_platform_service.dart`

## Workflow

1. Reproduce failure with exact command and keep raw logs.
2. Identify failure layer (Dart analyzer, Flutter toolchain, Gradle, Android manifest, iOS project/config).
3. Apply minimal targeted fix.
4. Re-run only the failing command first, then full verification set.
5. Report root cause, fix summary, and any residual risks.

## Guardrails

- Do not reintroduce browser or Web-only scope.
- Do not add Android permissions unless required by active runtime code.
- Prefer compatibility fixes that match current Flutter stable templates.
- If a fix is platform-specific, verify the other mobile target is not obviously broken.
