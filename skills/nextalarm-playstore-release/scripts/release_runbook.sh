#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

HELPER_SCRIPT="./scripts/release_android_playstore.sh"
CMD=""
TRACK="${PLAY_TRACK:-internal}"
FROM_TRACK=""
TO_TRACK=""
SERVICE_ACCOUNT="${PLAY_SERVICE_ACCOUNT_JSON:-}"
RUN_TESTS=0
ALLOW_ANALYZE_ISSUES=0
DRY_RUN=0
INTERNAL_VERIFIED=0
FLUTTER_BUILD_ARGS=()

usage() {
  cat <<'EOF'
Usage:
  skills/nextalarm-playstore-release/scripts/release_runbook.sh preflight [--with-tests]
  skills/nextalarm-playstore-release/scripts/release_runbook.sh build [-- <flutter args...>]
  skills/nextalarm-playstore-release/scripts/release_runbook.sh upload --track <track> --service-account <json>
  skills/nextalarm-playstore-release/scripts/release_runbook.sh build-upload --track <track> --service-account <json> [-- <flutter args...>]
  skills/nextalarm-playstore-release/scripts/release_runbook.sh promote --from-track internal --to-track production --service-account <json> --internal-verified

Commands:
  preflight     Run local checks (analyze and optional test).
  build         Build signed AAB using repository release script.
  upload        Upload existing AAB to Play track.
  build-upload  Build signed AAB then upload to Play track.
  promote       Promote release artifact between tracks (recommended: internal -> production).

Options:
  --with-tests                Run flutter test in preflight.
  --allow-analyze-issues      Continue even if flutter analyze is non-zero.
  --dry-run                   Print commands without executing.
  --track <track>             Play track. Default: internal.
  --from-track <track>        Source track for promote.
  --to-track <track>          Destination track for promote.
  --service-account <json>    Path to Play service account JSON.
  --internal-verified         Confirm internal testing is complete before production.
  --                          Remaining args are passed to flutter build appbundle.
EOF
}

die() {
  echo "[ERROR] $*" >&2
  exit 1
}

run_or_echo() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] $*"
  else
    "$@"
  fi
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

ensure_repo_script() {
  [[ -x "$HELPER_SCRIPT" ]] || die "Missing or non-executable script: $HELPER_SCRIPT"
}

run_preflight() {
  require_cmd flutter
  local analyze_exit=0
  local analyze_log=""

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] flutter analyze"
  else
    analyze_log="$(mktemp)"
    set +e
    flutter analyze 2>&1 | tee "$analyze_log"
    analyze_exit=${PIPESTATUS[0]}
    set -e
    if [[ "$analyze_exit" -ne 0 ]]; then
      if [[ "$ALLOW_ANALYZE_ISSUES" -eq 1 ]] && grep -q "issues found" "$analyze_log"; then
        echo "[WARN] flutter analyze returned non-zero ($analyze_exit) with analyzer findings, continuing due to --allow-analyze-issues."
      else
        die "flutter analyze failed with code $analyze_exit. Use --allow-analyze-issues to continue."
      fi
    fi
    rm -f "$analyze_log"
  fi

  if [[ "$RUN_TESTS" -eq 1 ]]; then
    run_or_echo flutter test
  fi
  echo "[INFO] Preflight checks completed."
}

run_build() {
  ensure_repo_script
  if [[ ${#FLUTTER_BUILD_ARGS[@]} -gt 0 ]]; then
    run_or_echo "$HELPER_SCRIPT" build -- "${FLUTTER_BUILD_ARGS[@]}"
  else
    run_or_echo "$HELPER_SCRIPT" build
  fi
}

run_upload() {
  ensure_repo_script
  [[ -n "$SERVICE_ACCOUNT" ]] || die "--service-account or PLAY_SERVICE_ACCOUNT_JSON is required for upload."
  local verified_arg=()
  if [[ "$INTERNAL_VERIFIED" -eq 1 ]]; then
    verified_arg+=("--internal-verified")
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] PLAY_SERVICE_ACCOUNT_JSON=\"$SERVICE_ACCOUNT\" PLAY_TRACK=\"$TRACK\" \"$HELPER_SCRIPT\" upload --track \"$TRACK\" ${verified_arg[*]}"
  else
    PLAY_SERVICE_ACCOUNT_JSON="$SERVICE_ACCOUNT" PLAY_TRACK="$TRACK" \
      "$HELPER_SCRIPT" upload --track "$TRACK" "${verified_arg[@]}"
  fi
}

run_build_upload() {
  ensure_repo_script
  [[ -n "$SERVICE_ACCOUNT" ]] || die "--service-account or PLAY_SERVICE_ACCOUNT_JSON is required for build-upload."
  local verified_arg=()
  if [[ "$INTERNAL_VERIFIED" -eq 1 ]]; then
    verified_arg+=("--internal-verified")
  fi
  if [[ ${#FLUTTER_BUILD_ARGS[@]} -gt 0 ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] PLAY_SERVICE_ACCOUNT_JSON=\"$SERVICE_ACCOUNT\" PLAY_TRACK=\"$TRACK\" \"$HELPER_SCRIPT\" build-upload --track \"$TRACK\" ${verified_arg[*]} -- ${FLUTTER_BUILD_ARGS[*]}"
    else
      PLAY_SERVICE_ACCOUNT_JSON="$SERVICE_ACCOUNT" PLAY_TRACK="$TRACK" \
        "$HELPER_SCRIPT" build-upload --track "$TRACK" "${verified_arg[@]}" -- "${FLUTTER_BUILD_ARGS[@]}"
    fi
  else
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[DRY-RUN] PLAY_SERVICE_ACCOUNT_JSON=\"$SERVICE_ACCOUNT\" PLAY_TRACK=\"$TRACK\" \"$HELPER_SCRIPT\" build-upload --track \"$TRACK\" ${verified_arg[*]}"
    else
      PLAY_SERVICE_ACCOUNT_JSON="$SERVICE_ACCOUNT" PLAY_TRACK="$TRACK" \
        "$HELPER_SCRIPT" build-upload --track "$TRACK" "${verified_arg[@]}"
    fi
  fi
}

run_promote() {
  ensure_repo_script
  [[ -n "$SERVICE_ACCOUNT" ]] || die "--service-account or PLAY_SERVICE_ACCOUNT_JSON is required for promote."
  [[ -n "$FROM_TRACK" ]] || die "--from-track is required for promote."
  [[ -n "$TO_TRACK" ]] || die "--to-track is required for promote."

  local verified_arg=()
  if [[ "$INTERNAL_VERIFIED" -eq 1 ]]; then
    verified_arg+=("--internal-verified")
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] PLAY_SERVICE_ACCOUNT_JSON=\"$SERVICE_ACCOUNT\" \"$HELPER_SCRIPT\" promote --from-track \"$FROM_TRACK\" --to-track \"$TO_TRACK\" ${verified_arg[*]}"
  else
    PLAY_SERVICE_ACCOUNT_JSON="$SERVICE_ACCOUNT" \
      "$HELPER_SCRIPT" promote --from-track "$FROM_TRACK" --to-track "$TO_TRACK" "${verified_arg[@]}"
  fi
}

parse_args() {
  [[ $# -gt 0 ]] || { usage; exit 1; }
  while [[ $# -gt 0 ]]; do
    case "$1" in
      preflight|build|upload|build-upload|promote)
        [[ -z "$CMD" ]] || die "Command already set to '$CMD'"
        CMD="$1"
        shift
        ;;
      --with-tests)
        RUN_TESTS=1
        shift
        ;;
      --allow-analyze-issues)
        ALLOW_ANALYZE_ISSUES=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --track)
        TRACK="${2:-}"
        [[ -n "$TRACK" ]] || die "--track requires a value"
        shift 2
        ;;
      --from-track)
        FROM_TRACK="${2:-}"
        [[ -n "$FROM_TRACK" ]] || die "--from-track requires a value"
        shift 2
        ;;
      --to-track)
        TO_TRACK="${2:-}"
        [[ -n "$TO_TRACK" ]] || die "--to-track requires a value"
        shift 2
        ;;
      --service-account)
        SERVICE_ACCOUNT="${2:-}"
        [[ -n "$SERVICE_ACCOUNT" ]] || die "--service-account requires a value"
        shift 2
        ;;
      --internal-verified)
        INTERNAL_VERIFIED=1
        shift
        ;;
      --)
        shift
        while [[ $# -gt 0 ]]; do
          FLUTTER_BUILD_ARGS+=("$1")
          shift
        done
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  case "$CMD" in
    preflight)
      run_preflight
      ;;
    build)
      run_build
      ;;
    upload)
      run_upload
      ;;
    build-upload)
      run_build_upload
      ;;
    promote)
      run_promote
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
