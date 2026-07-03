#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/clipboard-service-tests"
mkdir -p "$BUILD_DIR"

swiftc \
  "$ROOT_DIR/Sources/EarthAgent/Services/ClipboardService.swift" \
  "$ROOT_DIR/Scripts/clipboard_service_tests.swift" \
  -o "$BUILD_DIR/clipboard_service_tests"

"$BUILD_DIR/clipboard_service_tests"
