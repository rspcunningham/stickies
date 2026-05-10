#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Stickies"
BUNDLE_ID="dev.rspcunningham.stickies"
MIN_SYSTEM_VERSION="26.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ENTITLEMENTS="$ROOT_DIR/Stickies.entitlements"
SIGNED_ENTITLEMENTS="$DIST_DIR/Stickies.signed.entitlements"
PROFILE_PLIST="$DIST_DIR/Stickies.provisioning-profile.plist"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"
PROVISIONING_PROFILE="${PROVISIONING_PROFILE:-}"
CODESIGN_OPTIONS="${CODESIGN_OPTIONS:---options runtime}"
APS_ENVIRONMENT="${APS_ENVIRONMENT:-development}"

cd "$ROOT_DIR"

pkill -f "$APP_BINARY" >/dev/null 2>&1 || true

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ -n "$CODESIGN_IDENTITY" && -f "$ENTITLEMENTS" ]]; then
  if [[ -z "$PROVISIONING_PROFILE" ]]; then
    echo "CODESIGN_IDENTITY was set, but PROVISIONING_PROFILE was not." >&2
    echo "CloudKit entitlements require a matching embedded provisioning profile." >&2
    exit 2
  fi

  cp "$PROVISIONING_PROFILE" "$APP_CONTENTS/embedded.provisionprofile"
  /usr/bin/security cms -D -i "$PROVISIONING_PROFILE" > "$PROFILE_PLIST"

  APP_IDENTIFIER="$(/usr/libexec/PlistBuddy -c "Print :Entitlements:com.apple.application-identifier" "$PROFILE_PLIST")"
  TEAM_IDENTIFIER="$(/usr/libexec/PlistBuddy -c "Print :Entitlements:com.apple.developer.team-identifier" "$PROFILE_PLIST")"

  cp "$ENTITLEMENTS" "$SIGNED_ENTITLEMENTS"
  /usr/libexec/PlistBuddy -c "Set :com.apple.developer.aps-environment $APS_ENVIRONMENT" "$SIGNED_ENTITLEMENTS"
  /usr/libexec/PlistBuddy -c "Delete :com.apple.application-identifier" "$SIGNED_ENTITLEMENTS" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Add :com.apple.application-identifier string $APP_IDENTIFIER" "$SIGNED_ENTITLEMENTS"
  /usr/libexec/PlistBuddy -c "Delete :com.apple.developer.team-identifier" "$SIGNED_ENTITLEMENTS" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string $TEAM_IDENTIFIER" "$SIGNED_ENTITLEMENTS"

  # shellcheck disable=SC2086
  /usr/bin/codesign --force --sign "$CODESIGN_IDENTITY" $CODESIGN_OPTIONS --entitlements "$SIGNED_ENTITLEMENTS" "$APP_BUNDLE" >/dev/null
else
  /usr/bin/codesign --force --sign - "$APP_BUNDLE" >/dev/null
fi

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -f "$APP_BINARY" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
