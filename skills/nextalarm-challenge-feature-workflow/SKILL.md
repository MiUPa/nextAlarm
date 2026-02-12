---
name: nextalarm-challenge-feature-workflow
description: Implement or modify wake-up challenge features in NextAlarm across model, edit UI, ringing flow, localization, permissions, and validation. Use when adding a new challenge type or changing challenge behavior/difficulty.
---

# Goal

Apply challenge-related changes consistently without missing model/UI/runtime/l10n integration points.

## Use Bundled Resources

- Read `references/file-change-map.md` to identify impacted files by change type.
- Read `references/regression-checklist.md` before final verification.

## Core Files

Start from these files unless the request clearly scopes narrower:

- `lib/models/alarm.dart`
- `lib/screens/alarm_edit_screen.dart`
- `lib/screens/alarm_ringing_screen.dart`
- `lib/services/alarm_service.dart`
- `lib/l10n/app_ja.arb`
- `lib/l10n/app_en.arb`
- `android/app/src/main/AndroidManifest.xml` (if permission/behavior changes)

## Workflow

1. Define challenge contract.
- Define challenge identifier, required inputs, success criteria, and fallback behavior.
- Decide compatibility behavior for previously saved alarms.

2. Update model and persistence.
- Add/modify enum or data fields in `lib/models/alarm.dart`.
- Ensure serialization/deserialization remains backward compatible.

3. Update edit screen configuration.
- Add challenge option and settings controls in `lib/screens/alarm_edit_screen.dart`.
- Set safe defaults for new fields.

4. Update ringing behavior.
- Implement validation logic and completion path in `lib/screens/alarm_ringing_screen.dart`.
- Keep stop-alarm behavior deterministic (no accidental bypass unless explicitly requested).

5. Update service and scheduling dependencies.
- Apply any runtime hooks in `lib/services/alarm_service.dart`.
- Add required package/manifest changes if sensors, camera, mic, or other platform APIs are needed.

6. Update localization.
- Add new strings in `lib/l10n/app_ja.arb` and `lib/l10n/app_en.arb`.
- Regenerate l10n outputs when required by the project setup.

7. Validate.
- Run `flutter analyze`.
- Run targeted tests or manual smoke for:
  - New challenge happy path
  - Wrong answer/retry path
  - Existing challenge regression check

8. Report outcome.
- List modified files, compatibility notes, and remaining risk or follow-up items.

## Guardrails

- Keep enum and persisted values stable to avoid breaking saved alarms.
- Avoid adding platform permissions unless the challenge actually uses them.
- If a feature is partially implemented, explicitly surface fallback UX.
