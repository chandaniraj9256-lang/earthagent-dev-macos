#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/Earth Agent.app"
INSTALL_DIR="/Applications/Earth Agent.app"
EXECUTABLE="$APP_DIR/Contents/MacOS/EarthAgent"
INFO_PLIST="$APP_DIR/Contents/Info.plist"

cd "$ROOT_DIR"

echo "== Earth Agent release smoke test =="

echo "[1/11] Planner safety tests"
"$ROOT_DIR/Scripts/planner_safety_tests.sh" >/dev/null

echo "[2/11] Streaming parser tests"
"$ROOT_DIR/Scripts/streaming_client_tests.sh" >/dev/null

echo "[3/11] Spoken text cleaner tests"
"$ROOT_DIR/Scripts/spoken_text_cleaner_tests.sh" >/dev/null

echo "[4/11] Clipboard service tests"
"$ROOT_DIR/Scripts/clipboard_service_tests.sh" >/dev/null

echo "[5/11] Note writer tests"
"$ROOT_DIR/Scripts/note_writer_tests.sh" >/dev/null

echo "[6/11] Debug build"
swift build >/dev/null

echo "[7/11] Production app bundle"
"$ROOT_DIR/Scripts/build_app.sh" >/dev/null

echo "[8/11] Bundle structure"
test -d "$APP_DIR"
test -f "$EXECUTABLE"
test -x "$EXECUTABLE"
test -f "$INFO_PLIST"
test -f "$APP_DIR/Contents/Resources/EarthAgent.entitlements"

echo "[9/11] Info.plist"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PLIST")"
bundle_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' "$INFO_PLIST")"
microphone_usage="$(/usr/libexec/PlistBuddy -c 'Print :NSMicrophoneUsageDescription' "$INFO_PLIST")"
speech_usage="$(/usr/libexec/PlistBuddy -c 'Print :NSSpeechRecognitionUsageDescription' "$INFO_PLIST")"
screen_usage="$(/usr/libexec/PlistBuddy -c 'Print :NSScreenCaptureUsageDescription' "$INFO_PLIST")"

test "$bundle_id" = "com.earthagent.desktop"
test "$bundle_name" = "Earth Agent"
test -n "$microphone_usage"
test -n "$speech_usage"
test -n "$screen_usage"

echo "[10/11] Code signature"
codesign --verify --deep --strict "$APP_DIR"

echo "[11/11] Install verification"
"$ROOT_DIR/Scripts/install_app.sh" >/dev/null
test -d "$INSTALL_DIR"
test -x "$INSTALL_DIR/Contents/MacOS/EarthAgent"
codesign --verify --deep --strict "$INSTALL_DIR"

echo "Release smoke test passed."
echo "Installed app: $INSTALL_DIR"
