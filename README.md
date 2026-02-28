# Next Alarm

[日本語](README.ja.md)

[![Flutter](https://img.shields.io/badge/Flutter-Mobile%20App-02569B?logo=flutter)](https://flutter.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](#current-scope)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Next Alarm is a mobile-first alarm clock for people who routinely sleep through normal alarms.
It is not trying to be the cutest reminder app on your phone. It is trying to help you cross the boundary between asleep and awake.

## Philosophy

Most alarm apps are good at scheduling time. Next Alarm is trying to be good at changing state.

The project is shaped by three ideas:

- Reliability matters more than novelty. An alarm only has value if it rings when you actually need it.
- Friction should be intentional. Wake-up challenges are not gimmicks; they are designed to force a small but real action.
- Utility apps should still feel calm and polished. A serious tool does not need to look harsh to do a hard job well.

## Current Scope

This repository is intentionally focused on the mobile app.
The earlier browser build and GitHub Pages deployment were removed to keep the scope honest and the maintenance surface smaller.

Android is the primary platform today. An iOS project is included, but alarm reliability work is still Android-first.

## Features

- Unlimited alarms with weekday repeat rules
- Wake-up challenges: none, math, voice recognition, shake, and steps
- Challenge difficulty, alarm sound, vibration intensity, and gradual-volume options
- Fullscreen alarm entry and challenge flow
- English and Japanese localization
- Native Android alarm scheduling and lock-screen-oriented alarm behavior

## Screenshots

| Home | Alarm editor | Settings |
| --- | --- | --- |
| ![Home screen](screenshots/01_home.png) | ![Alarm editor](screenshots/02_alarm_add.png) | ![Settings](screenshots/02_settings.png) |

## Tech Stack

- Flutter
- Dart
- Provider
- SharedPreferences
- flutter_local_notifications
- speech_to_text
- sensors_plus
- pedometer
- vibration

## Project Structure

```text
lib/
  models/      Domain models such as alarms and challenge settings
  screens/     Home, edit, entry, ringing, and settings screens
  services/    Alarm scheduling, updates, navigation, and platform helpers
  theme/       App theme and design tokens

android/       Android app shell and native alarm integration
ios/           iOS app shell
scripts/       Release helpers
screenshots/   README screenshots
docs/          Release notes and investigation notes
```

## Getting Started

### Prerequisites

- Flutter SDK compatible with the repository `pubspec.yaml`
- Android Studio and/or Xcode
- Android SDK, and Xcode if you plan to build for iOS

### Run locally

```bash
git clone https://github.com/MiUPa/nextAlarm.git
cd nextAlarm
flutter pub get
flutter run
```

### Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Play release helper
./scripts/release_android_playstore.sh build

# iOS (macOS only)
flutter build ios --release
```

## Contributing

Issues and pull requests are welcome.

If you contribute, keep the project direction in mind:

- Prefer changes that improve real-world wake-up reliability over novelty.
- Keep the repository mobile-first; browser-specific scope is intentionally out.
- When adding friction, make it purposeful and explain how it helps the user wake up.

## Roadmap

- Improve alarm reliability diagnostics across more Android devices
- Expand automated coverage for scheduling and ringing flows
- Continue bringing iOS behavior closer to Android parity
- Refine wake-up challenge tuning and customization

## License

MIT. See [LICENSE](LICENSE).
