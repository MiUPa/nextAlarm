#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

KEY_PROPS="android/key.properties"
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
GRADLEW="./android/gradlew"
DEFAULT_TRACK="internal"

TRACK="${PLAY_TRACK:-$DEFAULT_TRACK}"
PLAY_SERVICE_ACCOUNT_JSON_PATH="${PLAY_SERVICE_ACCOUNT_JSON:-}"
SKIP_BUILD=0
NO_COMMIT=0
CMD=""
RELEASE_STATUS="${PLAY_RELEASE_STATUS:-completed}"
USER_FRACTION="${PLAY_USER_FRACTION:-}"
UPDATE_PRIORITY="${PLAY_UPDATE_PRIORITY:-}"
FROM_TRACK=""
TO_TRACK=""
FLUTTER_BUILD_ARGS=()
INTERNAL_VERIFIED=0
ALLOW_DIRECT_PRODUCTION=0
ENFORCE_INTERNAL_FIRST="${PLAY_ENFORCE_INTERNAL_FIRST:-1}"

required_keys=(storeFile storePassword keyAlias keyPassword)

usage() {
	cat <<'EOF'
Usage:
  scripts/release_android_playstore.sh build [-- <flutter build args...>]
  scripts/release_android_playstore.sh upload [options]
  scripts/release_android_playstore.sh build-upload [options] [-- <flutter build args...>]
  scripts/release_android_playstore.sh promote [options]

Commands:
  build         Build signed Android App Bundle (AAB).
  upload        Upload release bundle to Google Play (uses Gradle Play Publisher).
  build-upload  Build signed AAB, then upload to Google Play.
  promote       Promote an already uploaded release from one track to another.

Options:
  --track <track>          Google Play upload track (default: internal).
  --from-track <track>     Source track for promote.
  --to-track <track>       Destination track for promote.
  --release-status <val>   completed|draft|halted|inProgress (default: completed).
  --user-fraction <num>    Required for inProgress staged rollout (e.g. 0.1).
  --update-priority <int>  In-app update priority (0-5).
  --internal-verified      Confirm internal testing on real devices is done.
  --allow-direct-production  Allow direct production upload/promote (override policy).
  --skip-build             Skip build step for upload/build-upload.
  --no-commit              Dry run for Play edit changes (Gradle Play Publisher).
  --                Treat the rest as flutter build appbundle arguments.
  -h, --help        Show this help.

Required env vars for upload:
  PLAY_SERVICE_ACCOUNT_JSON   Absolute or repo-relative path to Play service account JSON.

Optional env vars:
  PLAY_TRACK                  Default track when --track is omitted.
  PLAY_RELEASE_STATUS         Default release status when --release-status is omitted.
  PLAY_USER_FRACTION          Default user fraction when --user-fraction is omitted.
  PLAY_UPDATE_PRIORITY        Default update priority when --update-priority is omitted.
  PLAY_ENFORCE_INTERNAL_FIRST Set to 0 to disable internal->production policy guard.

Examples:
  scripts/release_android_playstore.sh build
  scripts/release_android_playstore.sh upload --track internal
  PLAY_SERVICE_ACCOUNT_JSON=/path/play.json scripts/release_android_playstore.sh build-upload --track internal
  PLAY_SERVICE_ACCOUNT_JSON=/path/play.json scripts/release_android_playstore.sh promote --from-track internal --to-track production --internal-verified
EOF
}

log_info() {
	echo "[INFO] $*"
}

log_error() {
	echo "[ERROR] $*" >&2
}

require_cmd() {
	local cmd="$1"
	if ! command -v "$cmd" >/dev/null 2>&1; then
		log_error "Required command not found: $cmd"
		exit 1
	fi
}

resolve_service_account_path() {
	if [[ -z "$PLAY_SERVICE_ACCOUNT_JSON_PATH" ]]; then
		log_error "PLAY_SERVICE_ACCOUNT_JSON is not set."
		log_error "Set it to your Play service account JSON path before upload."
		exit 1
	fi

	if [[ -f "$PLAY_SERVICE_ACCOUNT_JSON_PATH" ]]; then
		PLAY_SERVICE_ACCOUNT_JSON_PATH="$(cd "$(dirname "$PLAY_SERVICE_ACCOUNT_JSON_PATH")" && pwd)/$(basename "$PLAY_SERVICE_ACCOUNT_JSON_PATH")"
		return
	fi

	if [[ -f "$ROOT_DIR/$PLAY_SERVICE_ACCOUNT_JSON_PATH" ]]; then
		PLAY_SERVICE_ACCOUNT_JSON_PATH="$ROOT_DIR/$PLAY_SERVICE_ACCOUNT_JSON_PATH"
		return
	fi

	log_error "Service account JSON not found: $PLAY_SERVICE_ACCOUNT_JSON_PATH"
	exit 1
}

validate_signing() {
	if [[ ! -f "$KEY_PROPS" ]]; then
		log_error "Missing $KEY_PROPS"
		log_error "Create it before building signed release."
		exit 1
	fi

	for key in "${required_keys[@]}"; do
		if ! grep -qE "^${key}=.+" "$KEY_PROPS"; then
			log_error "Missing key '${key}' in $KEY_PROPS"
			exit 1
		fi
	done

	local store_file
	store_file="$(grep -E '^storeFile=' "$KEY_PROPS" | head -n1 | cut -d= -f2-)"
	if [[ -z "$store_file" ]]; then
		log_error "storeFile is empty in $KEY_PROPS"
		exit 1
	fi

	if [[ -f "$store_file" ]]; then
		log_info "Keystore found: $store_file"
	elif [[ -f "android/$store_file" ]]; then
		log_info "Keystore found: android/$store_file"
	else
		log_error "Keystore file not found: '$store_file'"
		log_error "Tried: $store_file and android/$store_file"
		exit 1
	fi
}

build_aab() {
	require_cmd flutter
	validate_signing

	log_info "Fetching dependencies..."
	flutter pub get

	log_info "Building signed Android App Bundle..."
	if [[ ${#FLUTTER_BUILD_ARGS[@]} -gt 0 ]]; then
		flutter build appbundle --release "${FLUTTER_BUILD_ARGS[@]}"
	else
		flutter build appbundle --release
	fi

	if [[ ! -f "$AAB_PATH" ]]; then
		log_error "Build finished but AAB not found at: $AAB_PATH"
		exit 1
	fi

	log_info "AAB created: $AAB_PATH"
	shasum -a 256 "$AAB_PATH"
	ls -lh "$AAB_PATH"
}

validate_production_upload_policy() {
	if [[ "$TRACK" != "production" ]]; then
		return
	fi

	if [[ "$INTERNAL_VERIFIED" -ne 1 ]]; then
		log_error "Production upload requires --internal-verified after real-device internal testing."
		exit 1
	fi

	if [[ "$ENFORCE_INTERNAL_FIRST" == "1" && "$ALLOW_DIRECT_PRODUCTION" -ne 1 ]]; then
		log_error "Direct upload to production is blocked by policy."
		log_error "Use internal testing first, then promote to production."
		log_error "If you must bypass, pass --allow-direct-production."
		exit 1
	fi
}

validate_production_promote_policy() {
	if [[ "$TO_TRACK" != "production" ]]; then
		return
	fi

	if [[ "$INTERNAL_VERIFIED" -ne 1 ]]; then
		log_error "Promoting to production requires --internal-verified."
		exit 1
	fi

	if [[ "$ENFORCE_INTERNAL_FIRST" == "1" && "$FROM_TRACK" != "internal" && "$ALLOW_DIRECT_PRODUCTION" -ne 1 ]]; then
		log_error "Policy requires internal -> production promotion."
		log_error "Given: --from-track $FROM_TRACK --to-track $TO_TRACK"
		log_error "If you must bypass, pass --allow-direct-production."
		exit 1
	fi
}

upload_to_play() {
	validate_signing
	resolve_service_account_path
	validate_production_upload_policy

	if [[ "$SKIP_BUILD" -eq 0 ]]; then
		build_aab
	fi

	if [[ ! -x "$GRADLEW" ]]; then
		log_error "Gradle wrapper not executable: $GRADLEW"
		exit 1
	fi

	local gradle_args=(":app:publishReleaseBundle" "--track" "$TRACK" "--release-status" "$RELEASE_STATUS")
	if [[ -n "$USER_FRACTION" ]]; then
		gradle_args+=("--user-fraction" "$USER_FRACTION")
	fi
	if [[ -n "$UPDATE_PRIORITY" ]]; then
		gradle_args+=("--update-priority" "$UPDATE_PRIORITY")
	fi
	if [[ "$NO_COMMIT" -eq 1 ]]; then
		gradle_args+=("--no-commit")
	fi

	log_info "Uploading to Google Play track: $TRACK"
	log_info "Release status: $RELEASE_STATUS"
	log_info "Using service account JSON: $PLAY_SERVICE_ACCOUNT_JSON_PATH"
	PLAY_TRACK="$TRACK" PLAY_SERVICE_ACCOUNT_JSON="$PLAY_SERVICE_ACCOUNT_JSON_PATH" \
		"$GRADLEW" -p android "${gradle_args[@]}"

	log_info "Upload task completed."
}

promote_release() {
	resolve_service_account_path

	if [[ -z "$FROM_TRACK" || -z "$TO_TRACK" ]]; then
		log_error "promote requires --from-track and --to-track."
		exit 1
	fi
	validate_production_promote_policy

	local gradle_args=(
		":app:promoteReleaseArtifact"
		"--from-track" "$FROM_TRACK"
		"--promote-track" "$TO_TRACK"
		"--release-status" "$RELEASE_STATUS"
	)
	if [[ -n "$USER_FRACTION" ]]; then
		gradle_args+=("--user-fraction" "$USER_FRACTION")
	fi
	if [[ -n "$UPDATE_PRIORITY" ]]; then
		gradle_args+=("--update-priority" "$UPDATE_PRIORITY")
	fi
	if [[ "$NO_COMMIT" -eq 1 ]]; then
		gradle_args+=("--no-commit")
	fi

	log_info "Promoting release: $FROM_TRACK -> $TO_TRACK"
	log_info "Release status: $RELEASE_STATUS"
	log_info "Using service account JSON: $PLAY_SERVICE_ACCOUNT_JSON_PATH"
	PLAY_SERVICE_ACCOUNT_JSON="$PLAY_SERVICE_ACCOUNT_JSON_PATH" \
		"$GRADLEW" -p android "${gradle_args[@]}"

	log_info "Promote task completed."
}

parse_args() {
	if [[ $# -eq 0 ]]; then
		CMD="build"
		return
	fi

	while [[ $# -gt 0 ]]; do
		case "$1" in
			build|upload|build-upload|promote)
				if [[ -n "$CMD" ]]; then
					log_error "Command already set to '$CMD', got '$1'"
					exit 1
				fi
				CMD="$1"
				shift
				;;
			--track)
				TRACK="${2:-}"
				if [[ -z "$TRACK" ]]; then
					log_error "--track requires a value"
					exit 1
				fi
				shift 2
				;;
			--from-track)
				FROM_TRACK="${2:-}"
				if [[ -z "$FROM_TRACK" ]]; then
					log_error "--from-track requires a value"
					exit 1
				fi
				shift 2
				;;
			--to-track)
				TO_TRACK="${2:-}"
				if [[ -z "$TO_TRACK" ]]; then
					log_error "--to-track requires a value"
					exit 1
				fi
				shift 2
				;;
			--release-status)
				RELEASE_STATUS="${2:-}"
				if [[ -z "$RELEASE_STATUS" ]]; then
					log_error "--release-status requires a value"
					exit 1
				fi
				shift 2
				;;
			--user-fraction)
				USER_FRACTION="${2:-}"
				if [[ -z "$USER_FRACTION" ]]; then
					log_error "--user-fraction requires a value"
					exit 1
				fi
				shift 2
				;;
			--update-priority)
				UPDATE_PRIORITY="${2:-}"
				if [[ -z "$UPDATE_PRIORITY" ]]; then
					log_error "--update-priority requires a value"
					exit 1
				fi
				shift 2
				;;
			--internal-verified)
				INTERNAL_VERIFIED=1
				shift
				;;
			--allow-direct-production)
				ALLOW_DIRECT_PRODUCTION=1
				shift
				;;
			--skip-build)
				SKIP_BUILD=1
				shift
				;;
			--no-commit)
				NO_COMMIT=1
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
				log_error "Unknown argument: $1"
				usage
				exit 1
				;;
		esac
	done

	if [[ -z "$CMD" ]]; then
		CMD="build"
	fi
}

main() {
	parse_args "$@"

	case "$CMD" in
		build)
			build_aab
			;;
		upload)
			upload_to_play
			;;
		build-upload)
			SKIP_BUILD=0
			upload_to_play
			;;
		promote)
			promote_release
			;;
		*)
			log_error "Unsupported command: $CMD"
			usage
			exit 1
			;;
	esac
}

main "$@"
