# Challenge Feature File Change Map

## Purpose

Use this map to avoid missing integration points when implementing or changing a wake-up challenge.

## Core Change Areas

1. Challenge identity and persistence
- `lib/models/alarm.dart`
- Typical changes: enum value, JSON mapping, backward compatibility handling.

2. Alarm edit UI and settings input
- `lib/screens/alarm_edit_screen.dart`
- Typical changes: selectable challenge option, option-specific controls, defaults.

3. Ringing validation and completion behavior
- `lib/screens/alarm_ringing_screen.dart`
- Typical changes: challenge widget, answer validation, success/failure transition.

4. Scheduling/runtime hooks
- `lib/services/alarm_service.dart`
- Typical changes: challenge metadata propagation and ring-state handling.

5. Localization
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ja.arb`
- Typical changes: labels, help text, error messages.

6. Platform permissions and dependencies (only when needed)
- `android/app/src/main/AndroidManifest.xml`
- `pubspec.yaml`
- Typical changes: camera, mic, sensors, pedometer package or permission updates.

## Change-Type to File Hints

- New challenge type:
  - Must update model, edit screen, ring screen, l10n.
  - May update manifest and `pubspec.yaml`.
- Difficulty tuning only:
  - Usually edit screen + ring screen + l10n.
- Validation rule change only:
  - Usually ring screen + optional model defaults.
- Rename challenge label only:
  - Usually l10n + any hard-coded UI references.

## Compatibility Notes

- Keep persisted enum/string values stable when possible.
- If migration is required, add explicit fallback for old saved alarms.

