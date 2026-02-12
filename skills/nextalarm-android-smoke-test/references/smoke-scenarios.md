# NextAlarm Android Smoke Scenarios

## Scope

Use this file to run minimum Android validation before merge or release.

## Environment Prep

1. Choose one target from `adb devices`.
Use helper command:
`skills/nextalarm-android-smoke-test/scripts/android_smoke.sh list-devices`
2. Confirm package name:
`com.nextalarm.next_alarm`
3. Use deterministic baseline when needed:
`adb -s <device_id> shell pm clear com.nextalarm.next_alarm`

## Scenario Set A (Minimum)

1. Launch app.
2. Add alarm scheduled 1-2 minutes ahead.
3. Confirm alarm rings and ring screen appears.
4. Complete or dismiss the challenge.
5. Confirm alarm stops and app remains responsive.

Pass criteria:
- Alarm triggers on schedule.
- User can stop alarm through intended path.
- No crash or stuck state.

## Scenario Set B (Regression)

1. Repeat Scenario Set A with at least one different challenge type.
2. Toggle a settings change relevant to alarms (for example vibration).
3. Relaunch app and confirm persisted settings/alarms are still valid.

Pass criteria:
- Existing challenge types are unaffected by new changes.
- Persisted data survives app restart.

## Evidence Capture

1. Capture screenshot:
`adb -s <device_id> exec-out screencap -p > /tmp/nextalarm-smoke.png`
2. Capture logs:
`adb -s <device_id> logcat -d > /tmp/nextalarm-smoke.log`
3. Include:
- Device ID
- Build type
- Scenario result
- Key log lines for failure

## Helper Script

Use:
`skills/nextalarm-android-smoke-test/scripts/android_smoke.sh run --device <device_id>`

Dry-run without side effects:
`skills/nextalarm-android-smoke-test/scripts/android_smoke.sh run --device <device_id> --dry-run`
