#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/planner-safety-tests"
TEST_BIN="$BUILD_DIR/planner_safety_tests"

mkdir -p "$BUILD_DIR"

swiftc \
  "$ROOT_DIR/Sources/EarthAgent/Services/AgentPlanner.swift" \
  "$ROOT_DIR/Sources/EarthAgent/Models/AgentTask.swift" \
  "$ROOT_DIR/Sources/EarthAgent/Models/SafetyMode.swift" \
  "$ROOT_DIR/Scripts/planner_safety_tests.swift" \
  -o "$TEST_BIN"

"$TEST_BIN"
