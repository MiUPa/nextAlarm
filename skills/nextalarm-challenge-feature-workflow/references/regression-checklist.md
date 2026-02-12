# Challenge Regression Checklist

## Minimum Verification Matrix

Run this checklist after challenge-related code changes.

1. Static checks
- `flutter analyze` passes.
- L10n generation is up to date when ARB files changed.

2. New or changed challenge: happy path
- Can select challenge in edit screen.
- Can save and reload alarm with selected challenge.
- Alarm rings and challenge UI appears.
- Valid completion stops alarm.

3. New or changed challenge: failure path
- Invalid attempt is rejected.
- Retry flow is clear and does not crash.
- Alarm does not stop on invalid completion.

4. Existing challenge regression
- Verify at least one previously supported challenge still works.
- Confirm "no challenge" flow still dismisses as expected.

5. Persistence and restart
- Restart app and confirm challenge settings remain correct.
- Old alarms created before change still load without crash.

6. Permissions and platform behavior
- If new permission was added, runtime prompt and denial behavior are handled.
- If no permission is needed, confirm no extra permission was added.

7. Reporting
- Capture:
  - Changed files
  - Pass/fail by checklist item
  - Known limitations or deferred fixes

