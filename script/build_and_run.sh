#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
VERSION="${2:-${VERSION:-0.1.2}}"
APP_NAME="Clipboard"
BUNDLE_ID="com.gabe.Clipboard"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_FRAMEWORKS="$APP_CONTENTS/Frameworks"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION-macos.zip"
APPCAST_PATH="$ROOT_DIR/appcast.xml"
APPCAST_URL="https://raw.githubusercontent.com/shirangabriel/clipboard/master/appcast.xml"
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-3y5+0DTC9cv4PcPoVsAtkJeW23G1DJJ3Yz/53iGTg/4=}"
SPARKLE_GENERATE_APPCAST="$ROOT_DIR/.build/artifacts/sparkle/Sparkle/bin/generate_appcast"

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
  <key>SUFeedURL</key>
  <string>$APPCAST_URL</string>
  <key>SUEnableAutomaticChecks</key>
  <true/>
  <key>SUAutomaticallyUpdate</key>
  <false/>
  <key>SUPublicEDKey</key>
  <string>$SPARKLE_PUBLIC_ED_KEY</string>
</dict>
</plist>
PLIST
}

sign_app_bundle() {
  codesign --force --deep --sign - "$APP_BUNDLE"
}

build_app_bundle() {
  local configuration="${1:-debug}"
  local build_binary
  local build_dir

  if [[ "$configuration" == "release" ]]; then
    swift build -c release
    build_dir="$(swift build -c release --show-bin-path)"
  else
    swift build
    build_dir="$(swift build --show-bin-path)"
  fi
  build_binary="$build_dir/$APP_NAME"

  rm -rf "$APP_BUNDLE"
  mkdir -p "$APP_MACOS" "$APP_FRAMEWORKS"
  cp "$build_binary" "$APP_BINARY"
  chmod +x "$APP_BINARY"
  cp -R "$build_dir/Sparkle.framework" "$APP_FRAMEWORKS/"
  install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BINARY" 2>/dev/null || true
  write_info_plist
  sign_app_bundle
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

generate_appcast() {
  package_app
  "$SPARKLE_GENERATE_APPCAST" \
    --download-url-prefix "https://github.com/shirangabriel/clipboard/releases/download/v$VERSION/" \
    --link "https://github.com/shirangabriel/clipboard/releases/tag/v$VERSION" \
    --versions "$VERSION" \
    -o "$APPCAST_PATH" \
    "$DIST_DIR"
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
  --appcast|appcast)
    generate_appcast
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--package|--appcast [version]]" >&2
    exit 2
    ;;
esac
