# Android Alarm Reliability Test Plan

## Preconditions
- Install the app on a physical Android device.
- Add at least one enabled alarm within 2-5 minutes.
- Confirm notification permission is granted.

## 1. Reboot Recovery
1. Create an enabled alarm a few minutes in the future.
2. Reboot the device.
3. Unlock and wait for the alarm time.
4. Expected: alarm rings and opens alarm UI flow.

## 2. Doze-Like Idle
1. Create an enabled alarm 10-20 minutes in the future.
2. Turn screen off and leave device untouched.
3. Expected: alarm fires near scheduled time without major delay.

## 3. Lock Screen Full-Screen UX
1. Lock the device before alarm time.
2. Wait for alarm trigger.
3. Expected: full-screen alarm flow appears (or high-priority fallback), sound/vibration continue until dismissed in app.

## 4. Permission Denied Guidance
1. Revoke exact alarm capability from system settings where possible.
2. Open app settings screen.
3. Expected: warning state is shown and "Open" action navigates to the proper system settings screen.

## 5. Force Stop Limitation
1. Force stop the app from Android settings.
2. Wait for a scheduled alarm time.
3. Expected: app may not ring (OS behavior). On next app launch, user sees reliability guidance in settings.
