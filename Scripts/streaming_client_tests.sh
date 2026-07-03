#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/streaming-tests"
mkdir -p "$BUILD_DIR"

swiftc \
  "$ROOT_DIR/Sources/EarthAgent/Services/StreamingChatParser.swift" \
  "$ROOT_DIR/Scripts/streaming_client_tests.swift" \
  -o "$BUILD_DIR/streaming_client_tests"

"$BUILD_DIR/streaming_client_tests"
