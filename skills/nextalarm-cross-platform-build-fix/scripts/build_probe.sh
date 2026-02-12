#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

DRY_RUN=0
SKIP_ANALYZE=0
SKIP_TEST=0
SKIP_WEB=0
SKIP_ANDROID=0
ANDROID_MODE="debug"

usage() {
  cat <<'EOF'
Usage:
  skills/nextalarm-cross-platform-build-fix/scripts/build_probe.sh [options]

Options:
  --dry-run                 Print commands without executing.
  --skip-analyze            Skip flutter analyze.
  --skip-test               Skip flutter test.
  --skip-web                Skip flutter build web.
  --skip-android            Skip Android build.
  --android-mode <mode>     debug or release (default: debug).
  -h, --help                Show this help.
EOF
}

die() {
  echo "[ERROR] $*" >&2
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

run_or_echo() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] $*"
  else
    "$@"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --skip-analyze)
        SKIP_ANALYZE=1
        shift
        ;;
      --skip-test)
        SKIP_TEST=1
        shift
        ;;
      --skip-web)
        SKIP_WEB=1
        shift
        ;;
      --skip-android)
        SKIP_ANDROID=1
        shift
        ;;
      --android-mode)
        ANDROID_MODE="${2:-}"
        [[ "$ANDROID_MODE" == "debug" || "$ANDROID_MODE" == "release" ]] || die "--android-mode must be debug or release"
        shift 2
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

run_android_build() {
  if [[ "$ANDROID_MODE" == "debug" ]]; then
    run_or_echo flutter build apk --debug
  else
    run_or_echo flutter build appbundle --release
  fi
}

main() {
  parse_args "$@"
  require_cmd flutter

  run_or_echo flutter --version
  run_or_echo flutter pub get

  if [[ "$SKIP_ANALYZE" -eq 0 ]]; then
    run_or_echo flutter analyze
  fi

  if [[ "$SKIP_TEST" -eq 0 ]]; then
    run_or_echo flutter test
  fi

  if [[ "$SKIP_WEB" -eq 0 ]]; then
    run_or_echo flutter build web
  fi

  if [[ "$SKIP_ANDROID" -eq 0 ]]; then
    run_android_build
  fi

  echo "[INFO] Build probe completed."
}

main "$@"
