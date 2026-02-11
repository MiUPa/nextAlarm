#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

CMD=""
DEVICE_ID=""
PACKAGE_NAME="com.nextalarm.next_alarm"
BUILD_TYPE="debug"
SKIP_BUILD=0
NO_GRANT=0
DRY_RUN=0
WAIT_SECONDS=5
LOG_FILE="/tmp/nextalarm-smoke.log"
SCREENSHOT_FILE="/tmp/nextalarm-smoke.png"
ACTIVITY_NAME=".MainActivity"

usage() {
  cat <<'EOF'
Usage:
  skills/nextalarm-android-smoke-test/scripts/android_smoke.sh list-devices
  skills/nextalarm-android-smoke-test/scripts/android_smoke.sh run --device <id> [options]

Options:
  --device <id>            adb device id (required)
  --build <debug|release>  Build type. Default: debug
  --package <name>         Android package name. Default: com.nextalarm.next_alarm
  --activity <name>        Activity name. Default: .MainActivity
  --skip-build             Skip flutter build step
  --no-grant               Skip permission grants
  --dry-run                Print commands without executing
  --wait-seconds <n>       Wait time after launch before capture. Default: 5
  --log-file <path>        Log output path. Default: /tmp/nextalarm-smoke.log
  --screenshot <path>      Screenshot output path. Default: /tmp/nextalarm-smoke.png
  -h, --help               Show this help
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

list_devices() {
  require_cmd adb
  adb devices -l
}

parse_args() {
  [[ $# -gt 0 ]] || { usage; exit 1; }
  while [[ $# -gt 0 ]]; do
    case "$1" in
      list-devices)
        [[ -z "$CMD" ]] || die "Command already set to '$CMD'"
        CMD="list-devices"
        shift
        ;;
      run)
        [[ -z "$CMD" ]] || die "Command already set to '$CMD'"
        CMD="run"
        shift
        ;;
      --device)
        DEVICE_ID="${2:-}"
        [[ -n "$DEVICE_ID" ]] || die "--device requires a value"
        shift 2
        ;;
      --build)
        BUILD_TYPE="${2:-}"
        [[ "$BUILD_TYPE" == "debug" || "$BUILD_TYPE" == "release" ]] || die "--build must be debug or release"
        shift 2
        ;;
      --package)
        PACKAGE_NAME="${2:-}"
        [[ -n "$PACKAGE_NAME" ]] || die "--package requires a value"
        shift 2
        ;;
      --activity)
        ACTIVITY_NAME="${2:-}"
        [[ -n "$ACTIVITY_NAME" ]] || die "--activity requires a value"
        shift 2
        ;;
      --skip-build)
        SKIP_BUILD=1
        shift
        ;;
      --no-grant)
        NO_GRANT=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --wait-seconds)
        WAIT_SECONDS="${2:-}"
        [[ "$WAIT_SECONDS" =~ ^[0-9]+$ ]] || die "--wait-seconds must be a non-negative integer"
        shift 2
        ;;
      --log-file)
        LOG_FILE="${2:-}"
        [[ -n "$LOG_FILE" ]] || die "--log-file requires a value"
        shift 2
        ;;
      --screenshot)
        SCREENSHOT_FILE="${2:-}"
        [[ -n "$SCREENSHOT_FILE" ]] || die "--screenshot requires a value"
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

check_device_online() {
  if ! adb devices | awk 'NR>1 {print $1, $2}' | grep -q "^${DEVICE_ID} device$"; then
    echo "[ERROR] Device '${DEVICE_ID}' is not online." >&2
    echo "[INFO] Available adb targets:" >&2
    adb devices -l >&2 || true
    exit 1
  fi
}

build_apk() {
  require_cmd flutter
  if [[ "$BUILD_TYPE" == "debug" ]]; then
    run_or_echo flutter build apk --debug
  else
    run_or_echo flutter build apk --release
  fi
}

resolve_apk_path() {
  if [[ "$BUILD_TYPE" == "debug" ]]; then
    echo "build/app/outputs/flutter-apk/app-debug.apk"
  else
    echo "build/app/outputs/flutter-apk/app-release.apk"
  fi
}

install_apk() {
  local apk_path
  apk_path="$(resolve_apk_path)"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] adb -s \"$DEVICE_ID\" install -r \"$apk_path\""
    return
  fi
  [[ -f "$apk_path" ]] || die "APK not found: $apk_path"
  adb -s "$DEVICE_ID" install -r "$apk_path"
}

grant_permissions() {
  run_or_echo adb -s "$DEVICE_ID" shell pm grant "$PACKAGE_NAME" android.permission.POST_NOTIFICATIONS || true
  run_or_echo adb -s "$DEVICE_ID" shell pm grant "$PACKAGE_NAME" android.permission.RECORD_AUDIO || true
  run_or_echo adb -s "$DEVICE_ID" shell pm grant "$PACKAGE_NAME" android.permission.CAMERA || true
  run_or_echo adb -s "$DEVICE_ID" shell pm grant "$PACKAGE_NAME" android.permission.BODY_SENSORS || true
}

launch_app() {
  run_or_echo adb -s "$DEVICE_ID" shell am start -n "${PACKAGE_NAME}/${ACTIVITY_NAME}"
}

capture_evidence() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] adb -s \"$DEVICE_ID\" exec-out screencap -p > \"$SCREENSHOT_FILE\""
    echo "[DRY-RUN] adb -s \"$DEVICE_ID\" logcat -d > \"$LOG_FILE\""
  else
    adb -s "$DEVICE_ID" exec-out screencap -p > "$SCREENSHOT_FILE"
    adb -s "$DEVICE_ID" logcat -d > "$LOG_FILE"
  fi
}

run_flow() {
  [[ -n "$DEVICE_ID" ]] || die "--device is required"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    require_cmd adb
    check_device_online
  else
    echo "[DRY-RUN] Skipping adb connectivity check for device \"$DEVICE_ID\""
  fi

  if [[ "$SKIP_BUILD" -eq 0 ]]; then
    build_apk
  fi

  install_apk

  if [[ "$NO_GRANT" -eq 0 ]]; then
    grant_permissions
  fi

  launch_app
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY-RUN] sleep $WAIT_SECONDS"
  else
    sleep "$WAIT_SECONDS"
  fi
  capture_evidence

  echo "[INFO] Smoke setup completed."
  echo "[INFO] Device: $DEVICE_ID"
  echo "[INFO] Package: $PACKAGE_NAME"
  echo "[INFO] Screenshot: $SCREENSHOT_FILE"
  echo "[INFO] Log file: $LOG_FILE"
  echo "[INFO] Continue with manual scenario from references/smoke-scenarios.md"
}

main() {
  parse_args "$@"
  case "$CMD" in
    list-devices)
      list_devices
      ;;
    run)
      run_flow
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
