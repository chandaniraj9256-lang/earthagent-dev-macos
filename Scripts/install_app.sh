#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/Earth Agent.app"
INSTALL_DIR="/Applications/Earth Agent.app"

"$ROOT_DIR/Scripts/build_app.sh"

if pgrep -x EarthAgent >/dev/null 2>&1; then
  pkill EarthAgent || true
fi

rm -rf "$INSTALL_DIR"
cp -R "$APP_DIR" "$INSTALL_DIR"

echo "Installed: $INSTALL_DIR"
echo "Open it from Applications, Launchpad, or with:"
echo "open '/Applications/Earth Agent.app'"
