# NextAlarm Play Release Checklist

## Scope

Use this checklist for Android Play Store releases in this repository.

## Inputs

- `pubspec.yaml` target version `X.Y.Z+N`
- Release track (`internal`, `alpha`, `beta`, `production`)
- Upload mode (`build`, `upload`, `build-upload`)
- Release note bullets

## Preflight

1. Confirm `version` in `pubspec.yaml` is incremented.
2. Confirm signing file exists locally:
`android/key.properties`
3. Confirm required keys exist in that file:
- `storeFile`
- `storePassword`
- `keyAlias`
- `keyPassword`
4. Confirm artifact path convention:
`build/app/outputs/bundle/release/app-release.aab`

## Quality Gate

1. Run:
`flutter analyze`
2. Run tests when needed:
`flutter test`

## Build and Upload

1. Preflight helper:
`skills/nextalarm-playstore-release/scripts/release_runbook.sh preflight`
2. Dry-run preflight:
`skills/nextalarm-playstore-release/scripts/release_runbook.sh preflight --dry-run`
3. Continue preflight despite known analyzer issues:
`skills/nextalarm-playstore-release/scripts/release_runbook.sh preflight --allow-analyze-issues`
4. Build helper:
`skills/nextalarm-playstore-release/scripts/release_runbook.sh build`
5. Build and upload helper:
`skills/nextalarm-playstore-release/scripts/release_runbook.sh build-upload --track internal --service-account /abs/path/play.json`
6. Direct repo script (equivalent):
`./scripts/release_android_playstore.sh <command>`

## Post Build Validation

1. Confirm AAB exists at:
`build/app/outputs/bundle/release/app-release.aab`
2. Record checksum and file size from build output.
3. Note track and upload result.

## Metadata Updates

1. Add or update:
`docs/playstore_release_notes_<version>.md`
2. Update:
`docs/playstore_release_checklist.md`
3. Include latest successful build number in docs.

## Manual Play Console Follow-up

1. Verify policy declarations for exact alarms and foreground service.
2. Verify Data safety and permissions disclosures.
3. Roll out via internal testing before production unless explicitly overridden.
