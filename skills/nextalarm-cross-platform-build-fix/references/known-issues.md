# Known Mobile Build Issues

## 1) Flutter/Gradle Compatibility Drift

Symptoms:
- Gradle sync/build errors after Flutter upgrade.
- Plugin DSL or Android Gradle Plugin mismatch.

Checks:
- Compare `android/settings.gradle.kts` and `android/build.gradle.kts` with current Flutter template.
- Verify Kotlin, AGP, and Gradle wrapper compatibility.

## 2) Manifest Permission/Component Errors

Symptoms:
- Android build passes but runtime feature crashes.
- Install warnings on API 33+ or API 34+.

Checks:
- `android/app/src/main/AndroidManifest.xml`
- Runtime permission requests in Dart logic.

Rule:
- Add only necessary permissions and ensure runtime requests exist for dangerous permissions.

## 3) iOS Project Drift

Symptoms:
- `flutter build ios` fails after plugin or Flutter upgrades.
- Pod install or Xcode project settings fall behind current templates.

Checks:
- `ios/Podfile`
- `ios/Runner/Info.plist`
- `ios/Runner.xcodeproj/project.pbxproj`

Rule:
- Prefer the smallest template-aligned fix that restores buildability without changing app behavior.

## 4) Analyzer / Deprecated API Noise

Symptoms:
- `flutter analyze` fails or becomes noisy after Flutter updates.
- App still runs, but deprecated Flutter APIs accumulate.

Checks:
- UI files under `lib/screens/`
- `lib/theme/app_theme.dart`

Rule:
- Prefer direct API replacements over adding ignores.

## 5) Dependency Constraint Conflicts

Symptoms:
- `pub get` resolves but build fails due transitive incompatibilities.
- New plugin version breaks one target.

Checks:
- `pubspec.yaml` constraints.
- `flutter pub outdated` output.

Rule:
- Prefer smallest viable version updates and verify analyze + Android build after each change.
