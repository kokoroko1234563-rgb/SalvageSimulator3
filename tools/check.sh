#!/usr/bin/env bash
# Runs every check. Use before each push:  bash tools/check.sh
#   1. StyLua formatting
#   2. selene lint
#   3. Roblox API names (Enums, classes, properties), against Roblox's real API
#   4. Lune tests: load every module, validate the data, build every vessel, biome,
#      secret course, item and the beach with real Roblox instances
#   5. Rojo build
set -u
cd "$(dirname "$0")/.."
failed=0
step() { echo; echo "== $1"; }

step "Formatting (stylua)"
stylua --check src tools/tests || failed=1

step "Lint (selene)"
if [ -f roblox.yml ] || selene generate-roblox-std >/dev/null 2>&1; then
	selene src || failed=1
else
	echo "skipped: couldn't get selene's Roblox standard library"
fi

step "Roblox API names"
python3 tools/check_api.py || failed=1

step "Lune tests"
lune run tools/tests/run.luau || failed=1

step "Rojo build"
rojo build -o "${TMPDIR:-/tmp}/SalvageSimulator3-check.rbxlx" >/dev/null && echo "built" || failed=1

echo
if [ "$failed" -ne 0 ]; then
	echo "CHECKS FAILED"
	exit 1
fi
echo "All checks passed"
