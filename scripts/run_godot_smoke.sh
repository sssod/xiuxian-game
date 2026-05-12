#!/usr/bin/env sh
set -eu

if [ -n "${GODOT_BIN:-}" ]; then
  GODOT="$GODOT_BIN"
elif command -v godot4 >/dev/null 2>&1; then
  GODOT="godot4"
elif command -v godot >/dev/null 2>&1; then
  GODOT="godot"
elif [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
  GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
else
  echo "Godot binary not found. Set GODOT_BIN=/path/to/godot or install godot4/godot on PATH." >&2
  exit 127
fi

exec "$GODOT" --headless --path . --script tools/smoke_runner.gd
