#!/usr/bin/env bash
# Creates a distributable DMG for Memo.app
# Usage: bash scripts/package-dmg.sh [VERSION]
#   VERSION defaults to "1.0"
# Outputs: Memo-v$VERSION.dmg in the repo root (ad-hoc signed)
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-1.0}"
APP="$REPO/Memo.app"
DMG_NAME="Memo-v${VERSION}.dmg"
DMG_PATH="$REPO/$DMG_NAME"
VOLUME_NAME="Memo ${VERSION}"
TMP_DMG="$REPO/tmp-memo-build.dmg"

if [ ! -d "$APP" ]; then
  echo "Error: Memo.app not found at $APP — run 'make app' first" >&2
  exit 1
fi

# Clean up any previous intermediate DMG
rm -f "$TMP_DMG" "$DMG_PATH"

echo "→ Creating temporary DMG volume"
hdiutil create \
  -size 50m \
  -volname "$VOLUME_NAME" \
  -fs HFS+ \
  -fsargs "-c c=2,a=2,b=2" \
  -format UDRW \
  "$TMP_DMG"

echo "→ Mounting DMG"
MOUNT_DIR="$(hdiutil attach -readwrite -noverify -noautoopen "$TMP_DMG" \
  | grep -E '/Volumes/' \
  | awk '{print $NF}')"

if [ -z "$MOUNT_DIR" ]; then
  echo "Error: Failed to mount DMG" >&2
  rm -f "$TMP_DMG"
  exit 1
fi

echo "→ Copying Memo.app to volume: $MOUNT_DIR"
cp -r "$APP" "$MOUNT_DIR/Memo.app"

echo "→ Creating Applications symlink"
ln -s /Applications "$MOUNT_DIR/Applications"

echo "→ Detaching volume"
hdiutil detach "$MOUNT_DIR" -quiet

echo "→ Converting to compressed DMG: $DMG_NAME"
hdiutil convert "$TMP_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_PATH"

rm -f "$TMP_DMG"

echo "→ Signing DMG ad-hoc"
codesign --force --sign - "$DMG_PATH"

echo "Done: $DMG_PATH"
