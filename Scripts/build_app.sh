#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/release"
APP_DIR="$ROOT_DIR/dist/Earth Agent.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"

swift build -c release

swift "$ROOT_DIR/Scripts/generate_app_icon.swift"
iconutil -c icns "$ROOT_DIR/Packaging/EarthAgent.iconset" -o "$ROOT_DIR/Packaging/EarthAgent.icns"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/EarthAgent" "$MACOS_DIR/EarthAgent"
cp "$ROOT_DIR/Packaging/EarthAgent-Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Packaging/EarthAgent.entitlements" "$RESOURCES_DIR/EarthAgent.entitlements"
cp "$ROOT_DIR/Packaging/EarthAgent.icns" "$RESOURCES_DIR/EarthAgent.icns"

chmod +x "$MACOS_DIR/EarthAgent"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR" >/dev/null
fi

echo "Built: $APP_DIR"
