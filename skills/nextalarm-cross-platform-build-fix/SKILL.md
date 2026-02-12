---
name: nextalarm-cross-platform-build-fix
description: Diagnose and fix build or compatibility regressions across Flutter Android and Web targets in NextAlarm, including conditional exports, Gradle/plugin compatibility, manifest/package updates, and reproducible verification commands.
---

# Goal

Resolve cross-platform build failures quickly while preserving behavior on both Android and Web.

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
- `lib/services/notification_service.dart`
- `lib/services/notification_service_web.dart`
- `lib/services/notification_service_stub.dart`

## Workflow

1. Reproduce failure with exact command and keep raw logs.
2. Identify failure layer (Dart analyzer, Flutter toolchain, Gradle, Android manifest, Web imports).
3. Apply minimal targeted fix.
4. Re-run only the failing command first, then full verification set.
5. Report root cause, fix summary, and any residual risks.

## Guardrails

- Keep conditional export class APIs identical between web/stub implementations.
- Do not add Android permissions unless required by active runtime code.
- Prefer compatibility fixes that match current Flutter stable templates.
- If a fix is platform-specific, verify the other platform still builds.

