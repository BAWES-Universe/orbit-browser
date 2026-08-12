#!/usr/bin/env bash
#
# build-app.sh — assemble OrbitBrowser.app from the SwiftPM build.
#
# Toolchain: Command Line Tools only (swift build, codesign, plutil).
# Output:    shells/macos/build/OrbitBrowser.app  (gitignored)
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/OrbitBrowser"
OUT="$ROOT/build/OrbitBrowser.app"
BIN="$PKG/.build/debug/OrbitBrowser"

echo "==> [1/5] swift build (SwiftPM, WebKit+AppKit linked)"
(cd "$PKG" && swift build)
test -x "$BIN" || { echo "ERROR: binary not found at $BIN" >&2; exit 1; }

echo "==> [2/5] assemble bundle at $OUT"
rm -rf "$OUT"
mkdir -p "$OUT/Contents/MacOS" "$OUT/Contents/Resources"
cp "$BIN" "$OUT/Contents/MacOS/OrbitBrowser"
cp "$PKG/Info.plist" "$OUT/Contents/Info.plist"
printf 'APPL????' > "$OUT/Contents/PkgInfo"

echo "==> [3/5] plutil -lint"
plutil -lint "$OUT/Contents/Info.plist"

echo "==> [4/5] ad-hoc codesign"
codesign --force --deep -s - "$OUT"

echo "==> [5/5] verify"
codesign --verify --strict "$OUT" && echo "codesign --verify: OK (strict)"
codesign -dv "$OUT" 2>&1 | sed -n '1,8p'
file "$OUT/Contents/MacOS/OrbitBrowser"

echo "==> done: $OUT"
