# Cross-Platform Build Check Order

## Purpose

Use this order to isolate failures quickly and avoid noisy multi-layer breakage.

## Baseline

1. `flutter --version`
2. `flutter pub get`

## Static Checks

1. `flutter analyze`
2. `flutter test`

## Platform Builds

1. Web build:
`flutter build web`
2. Android build (fast check):
`flutter build apk --debug`
3. Android release artifact (when needed):
`flutter build appbundle --release`

## Typical Isolation Strategy

1. If `flutter analyze` fails, fix Dart/API issues first.
2. If Web fails but Android passes, inspect conditional imports/exports and web-only APIs.
3. If Android Gradle fails, inspect `android/build.gradle.kts`, `android/settings.gradle.kts`, and plugin/dependency compatibility.
4. After fix, re-run the exact failing command, then re-run the full sequence.

## Helper Script

Run:
`skills/nextalarm-cross-platform-build-fix/scripts/build_probe.sh`

Dry-run:
`skills/nextalarm-cross-platform-build-fix/scripts/build_probe.sh --dry-run`

