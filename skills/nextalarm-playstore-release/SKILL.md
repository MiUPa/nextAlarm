---
name: nextalarm-playstore-release
description: Build and optionally upload signed Android App Bundles for NextAlarm with version/build validation, signing checks, and release-note/checklist updates. Use when preparing any Google Play internal or production release in this repository.
---

# Goal

Produce a release-ready AAB and release metadata with minimal manual mistakes.

## Use Bundled Resources

- Read `references/release-checklist.md` at the start of every release run.
- Run `scripts/release_runbook.sh` for preflight, build, and upload orchestration.
- Delegate final build/upload to repo script `scripts/release_android_playstore.sh`.
- Use `--dry-run` when validating command flow without side effects.
- Use `--allow-analyze-issues` only when known analyzer findings are being handled separately.

## Confirm Inputs

Confirm these values before running commands:

- Target app version (`X.Y.Z+N`) for `pubspec.yaml`
- Target Play track (`internal`, `alpha`, `beta`, or `production`)
- Build only or build+upload
- Short release-note bullets for Play Console

## Workflow

1. Validate release baseline.
- Read `pubspec.yaml` and confirm version/build number is incremented.
- Ensure `android/key.properties` exists locally and includes required keys.

2. Run quality gate.
- Run `flutter analyze`.
- Run `flutter test` when requested or when risky changes are included.

3. Build and upload.
- Build: `./scripts/release_android_playstore.sh build`
- Upload only: `PLAY_SERVICE_ACCOUNT_JSON=/abs/path/play.json ./scripts/release_android_playstore.sh upload --track internal`
- Build and upload: `PLAY_SERVICE_ACCOUNT_JSON=/abs/path/play.json ./scripts/release_android_playstore.sh build-upload --track internal`
- Promote to production after internal verification:
`PLAY_SERVICE_ACCOUNT_JSON=/abs/path/play.json ./scripts/release_android_playstore.sh promote --from-track internal --to-track production --internal-verified`

4. Verify release artifact.
- Confirm `build/app/outputs/bundle/release/app-release.aab` exists.
- Capture checksum and file size from script output.

5. Update release documents.
- Add or update `docs/playstore_release_notes_<version>.md`.
- Update `docs/playstore_release_checklist.md` status fields (including latest build number).

6. Report outcome.
- Report version, track, artifact path, upload result, and remaining manual Play Console tasks.

## Guardrails

- Never commit `android/key.properties` or service-account JSON.
- Stop and resolve analyzer/build errors before upload.
- Default policy is `internal -> production` with real-device verification in between.
- Production promotion requires explicit confirmation (`--internal-verified`).
