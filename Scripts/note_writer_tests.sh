#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/note-writer-tests"
mkdir -p "$BUILD_DIR"

swiftc \
  "$ROOT_DIR/Sources/EarthAgent/Services/NoteWriterService.swift" \
  "$ROOT_DIR/Scripts/note_writer_tests.swift" \
  -o "$BUILD_DIR/note_writer_tests"

"$BUILD_DIR/note_writer_tests"
