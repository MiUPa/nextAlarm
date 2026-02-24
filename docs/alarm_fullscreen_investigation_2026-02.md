# Alarm Full-Screen Not Showing While Using Another App: Investigation

## Reported symptom
- When alarm time arrives while another app is in foreground:
  - Sound and vibration start.
  - The alarm UI does **not** automatically take over the screen.

## Confirmed behavior from current implementation
1. Alarm trigger path starts native foreground ringing service.
   - `AlarmReceiver` starts `AlarmRingingService` and stores pending alarm ID.
2. `AlarmRingingService` builds a high-priority alarm notification and requests full-screen launch via `setFullScreenIntent(...)`.
3. Alarm UI on Flutter side is shown only after app foreground flow reaches `MainActivity` and `AlarmService` consumes pending ringing alarm ID.

## Root cause analysis

### 1) Full-screen launch is treated as **best-effort**, but app currently assumes it is guaranteed
On modern Android versions, full-screen notification launch can be blocked/suppressed by OS policy or user/device settings, even when `USE_FULL_SCREEN_INTENT` is declared.

Current code has:
- Manifest declaration for `USE_FULL_SCREEN_INTENT`.
- `setFullScreenIntent(...)` usage.

But current code lacks:
- Runtime capability check (Android 14+ `NotificationManager.canUseFullScreenIntent()`).
- User guidance path to open full-screen intent permission settings when denied.
- Fallback UX path designed for "FSI denied/suppressed" states.

Result: ringtone/vibration work (service is running), but app screen may not auto-open.

### 2) Notification fallback is incomplete when FSI does not launch activity
The ringing notification defines a full-screen pending intent and a stop action, but no normal content intent for tap-to-open behavior.

So when full-screen takeover is denied/suppressed, user may only hear/feel alarm and not get a reliable route to the alarm UI from notification body tap.

### 3) Existing test plan already hints this is a known risk area
`docs/android_alarm_reliability_testplan.md` says lock-screen flow expectation is
"full-screen alarm flow appears (**or high-priority fallback**)".

However, implementation currently leans on full-screen path and does not fully provide that fallback UX.

## Resolution plan

### Phase 1: Platform capability detection and user guidance
1. Add Android method-channel support to expose:
   - `canUseFullScreenIntent` (API 34+).
   - `openFullScreenIntentSettings` via `Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` (API 34+).
2. Add a settings warning card in Flutter when full-screen intent is unavailable.
3. Localize warning text (JA/EN) similarly to existing exact-alarm/battery guidance.

### Phase 2: Reliable fallback UX when FSI is not granted
1. Add `setContentIntent(...)` to ringing notification so tapping notification body opens alarm UI.
2. Keep high-priority alarm category and ongoing notification.
3. Optionally add action button "Open alarm" to make fallback explicit.

### Phase 3: Trigger-to-UI observability
1. Add structured logs around:
   - alarm trigger,
   - service start,
   - full-screen intent capability,
   - activity launch result path.
2. Add debug-only diagnostic state in app settings (last alarm trigger timestamp + UI launch path).

### Phase 4: Validation matrix
1. Validate on Android 12, 13, 14, 15 physical devices/emulators.
2. Scenarios:
   - lock screen,
   - other app foreground,
   - screen off,
   - DND on/off,
   - notification permission denied,
   - full-screen intent permission denied.
3. Expected:
   - If FSI allowed: auto takeover.
   - If FSI denied: immediate high-priority notification + one-tap open route always available.

## Prioritized action list (short)
1. Implement notification fallback (`setContentIntent`) first.
2. Implement Android 14+ full-screen permission check and settings deep link.
3. Add settings warning UI + translations.
4. Run and document cross-version regression using `docs/android_alarm_reliability_testplan.md` as base.
