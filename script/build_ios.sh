#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="$ROOT_DIR/Stickies.xcodeproj"
DESTINATION="${IOS_DESTINATION:-generic/platform=iOS Simulator}"
ACTION="${1:-build}"

cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required to generate the iOS Xcode project." >&2
  exit 2
fi

xcodegen generate --spec project.yml >/dev/null

xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme StickiesIOS \
  -configuration Debug \
  -destination "$DESTINATION" \
  -allowProvisioningUpdates \
  "$ACTION"
