# Known Cross-Platform Issues

## 1) Conditional Export Mismatch

Symptoms:
- Build fails when web/stub classes differ.
- Method not found on one platform.

Checks:
- `lib/services/notification_service.dart`
- `lib/services/notification_service_web.dart`
- `lib/services/notification_service_stub.dart`

Rule:
- Keep class names and public method signatures identical.

## 2) Web-Only API Usage in Shared Code

Symptoms:
- Android build fails due `dart:html` usage.
- Analyzer warns about web-only libraries.

Checks:
- Ensure `dart:html` stays in web-specific files only.
- Keep shared layer behind conditional export.

## 3) Flutter/Gradle Compatibility Drift

Symptoms:
- Gradle sync/build errors after Flutter upgrade.
- Plugin DSL or Android Gradle Plugin mismatch.

Checks:
- Compare `android/settings.gradle.kts` and `android/build.gradle.kts` with current Flutter template.
- Verify Kotlin, AGP, and Gradle wrapper compatibility.

## 4) Manifest Permission/Component Errors

Symptoms:
- Android build passes but runtime feature crashes.
- Install warnings on API 33+ or API 34+.

Checks:
- `android/app/src/main/AndroidManifest.xml`
- Runtime permission requests in Dart logic.

Rule:
- Add only necessary permissions and ensure runtime requests exist for dangerous permissions.

## 5) Dependency Constraint Conflicts

Symptoms:
- `pub get` resolves but build fails due transitive incompatibilities.
- New plugin version breaks one target.

Checks:
- `pubspec.yaml` constraints.
- `flutter pub outdated` output.

Rule:
- Prefer smallest viable version updates and verify both web + Android after each change.

