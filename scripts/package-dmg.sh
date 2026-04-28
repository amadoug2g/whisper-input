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
STAGING_DIR="$(mktemp -d)"

if [ ! -d "$APP" ]; then
  echo "Error: Memo.app not found at $APP — run 'make app' first" >&2
  exit 1
fi

rm -f "$DMG_PATH"

echo "→ Staging app bundle"
cp -r "$APP" "$STAGING_DIR/Memo.app"
ln -s /Applications "$STAGING_DIR/Applications"

echo "→ Creating DMG: $DMG_NAME"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "→ Signing DMG ad-hoc"
codesign --force --sign - "$DMG_PATH"

echo "Done: $DMG_PATH"
