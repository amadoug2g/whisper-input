#!/usr/bin/env bash
# Generates a placeholder AppIcon.icns using a Swift script + iconutil.
# Requires macOS 12+. Run once; replace with real artwork before App Store.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET="$REPO/.build/AppIcon.iconset"
ICNS="$REPO/WhisperInput.app/Contents/Resources/AppIcon.icns"

mkdir -p "$ICONSET"

# Generate the 1024×1024 base PNG via a Swift one-liner
swift "$REPO/scripts/generate-icon.swift" "$ICONSET/icon_512x512@2x.png"

# Derive all required sizes from the base using sips (built into macOS)
declare -a SIZES=(16 32 64 128 256 512)
for S in "${SIZES[@]}"; do
  sips -z "$S" "$S"   "$ICONSET/icon_512x512@2x.png" --out "$ICONSET/icon_${S}x${S}.png"       2>/dev/null
  sips -z "$((S*2))" "$((S*2))" "$ICONSET/icon_512x512@2x.png" --out "$ICONSET/icon_${S}x${S}@2x.png" 2>/dev/null
done
# 512@1x
sips -z 512 512 "$ICONSET/icon_512x512@2x.png" --out "$ICONSET/icon_512x512.png" 2>/dev/null

mkdir -p "$(dirname "$ICNS")"
iconutil -c icns "$ICONSET" -o "$ICNS"
echo "✓ AppIcon.icns → $ICNS"
