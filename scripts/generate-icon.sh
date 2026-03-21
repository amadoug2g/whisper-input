#!/usr/bin/env bash
# Generates a placeholder AppIcon.icns using a Swift script + iconutil.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET="$REPO/.build/AppIcon.iconset"
ICNS="$REPO/Memo.app/Contents/Resources/AppIcon.icns"

mkdir -p "$ICONSET"

swift "$REPO/scripts/generate-icon.swift" "$ICONSET/icon_512x512@2x.png"

declare -a SIZES=(16 32 64 128 256 512)
for S in "${SIZES[@]}"; do
  sips -z "$S" "$S"   "$ICONSET/icon_512x512@2x.png" --out "$ICONSET/icon_${S}x${S}.png"       2>/dev/null
  sips -z "$((S*2))" "$((S*2))" "$ICONSET/icon_512x512@2x.png" --out "$ICONSET/icon_${S}x${S}@2x.png" 2>/dev/null
done
sips -z 512 512 "$ICONSET/icon_512x512@2x.png" --out "$ICONSET/icon_512x512.png" 2>/dev/null

mkdir -p "$(dirname "$ICNS")"
iconutil -c icns "$ICONSET" -o "$ICNS"
echo "AppIcon.icns → $ICNS"
