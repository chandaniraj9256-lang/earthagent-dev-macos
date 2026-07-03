#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/spoken-cleaner-tests"
mkdir -p "$BUILD_DIR"

swiftc \
  "$ROOT_DIR/Sources/EarthAgent/Services/SpokenTextCleaner.swift" \
  "$ROOT_DIR/Scripts/spoken_text_cleaner_tests.swift" \
  -o "$BUILD_DIR/spoken_text_cleaner_tests"

"$BUILD_DIR/spoken_text_cleaner_tests"
