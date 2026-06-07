#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
VERSION="${2:-${VERSION:-0.1.1}}"
APP_NAME="Clipboard"
BUNDLE_ID="com.gabe.Clipboard"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION-macos.zip"

stop_running_app() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  pkill -f ".build.*$APP_NAME" >/dev/null 2>&1 || true
}

write_info_plist() {
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
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright (c) 2026 Gabe. All rights reserved.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST
}

build_app_bundle() {
  local configuration="${1:-debug}"
  local build_binary

  if [[ "$configuration" == "release" ]]; then
    swift build -c release
    build_binary="$(swift build -c release --show-bin-path)/$APP_NAME"
  else
    swift build
    build_binary="$(swift build --show-bin-path)/$APP_NAME"
  fi

  rm -rf "$APP_BUNDLE"
  mkdir -p "$APP_MACOS"
  cp "$build_binary" "$APP_BINARY"
  chmod +x "$APP_BINARY"
  write_info_plist
}

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

package_app() {
  build_app_bundle release
  rm -f "$ZIP_PATH"
  xattr -cr "$APP_BUNDLE"
  COPYFILE_DISABLE=1 ditto -c -k --norsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"
  shasum -a 256 "$ZIP_PATH"
}

case "$MODE" in
  run)
    stop_running_app
    build_app_bundle debug
    open_app
    ;;
  --debug|debug)
    stop_running_app
    build_app_bundle debug
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    stop_running_app
    build_app_bundle debug
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    stop_running_app
    build_app_bundle debug
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    stop_running_app
    build_app_bundle debug
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    stop_running_app
    ;;
  --package|package)
    package_app
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--package [version]]" >&2
    exit 2
    ;;
esac
