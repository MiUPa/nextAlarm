---
name: nextalarm-android-smoke-test
description: Run repeatable Android smoke tests for NextAlarm using flutter and adb, including install/launch, permission setup, alarm trigger validation, log capture, and screenshot evidence. Use when validating release candidates or debugging Android regressions.
---

# Goal

Verify that core Android alarm flows work end-to-end on emulator or real device.

## Use Bundled Resources

- Read `references/smoke-scenarios.md` to choose scenario set and pass/fail criteria.
- Run `scripts/android_smoke.sh` for repeatable setup, install, permission grants, and evidence capture.
- Use `scripts/android_smoke.sh list-devices` to select the target device.
- Use `--dry-run` to verify command flow before touching devices.

## Confirm Inputs

Confirm these values before execution:

- Device ID from `adb devices`
- Build target (`debug` or `release`)
- Package name (default: `com.nextalarm.next_alarm`)
- Required scenario list (minimum: create alarm -> ring -> dismiss)

## Workflow

1. Prepare target device.
- Run `adb devices` and select one online target.
- Optionally clear app data for deterministic runs:
  `adb -s <device_id> shell pm clear com.nextalarm.next_alarm`

2. Build and install app.
- Build debug: `flutter build apk --debug`
- Install: `adb -s <device_id> install -r build/app/outputs/flutter-apk/app-debug.apk`

3. Grant runtime permissions used by active features.
- Example:
  - `adb -s <device_id> shell pm grant com.nextalarm.next_alarm android.permission.POST_NOTIFICATIONS`
  - `adb -s <device_id> shell pm grant com.nextalarm.next_alarm android.permission.RECORD_AUDIO`
  - `adb -s <device_id> shell pm grant com.nextalarm.next_alarm android.permission.CAMERA`
  - `adb -s <device_id> shell pm grant com.nextalarm.next_alarm android.permission.BODY_SENSORS`

4. Launch and run smoke scenarios.
- Launch app:
  `adb -s <device_id> shell am start -n com.nextalarm.next_alarm/.MainActivity`
- Execute the minimum scenario set:
  - Add an alarm 1-2 minutes ahead
  - Wait for ring screen
  - Complete or dismiss challenge
  - Confirm alarm stops and app remains usable

5. Capture evidence.
- Capture screenshot(s):
  `adb -s <device_id> exec-out screencap -p > /tmp/nextalarm-smoke.png`
- Capture logs:
  `adb -s <device_id> logcat -d > /tmp/nextalarm-smoke.log`

6. Report outcome.
- Report pass/fail by scenario, device/build used, key logs, and reproducible failure steps.

## Guardrails

- Avoid fixed tap coordinates unless screen size/device is fixed for this run.
- Prefer explicit package/activity commands to reduce ambiguity.
- If a failure depends on timing, run the scenario at least twice before concluding.
