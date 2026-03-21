#!/bin/bash
# Builds Memo and launches it as a proper .app bundle.
#
# Accessibility permission is preserved across restarts by only re-signing
# when the binary actually changed. macOS tracks Accessibility by CDHash
# (code signature hash) — if the binary is identical, the CDHash is
# identical, and the TCC entry stays valid. No re-grant needed.
#
# Run: chmod +x run.sh && ./run.sh

set -euo pipefail

APP_NAME="Memo"
BUNDLE="${APP_NAME}.app"
BINARY_SRC=".build/debug/MemoMain"
BINARY_DEST="$BUNDLE/Contents/MacOS/$APP_NAME"

echo "Building…"
swift build 2>&1

# Kill any running instance so the new one can start cleanly
if pgrep -xq "$APP_NAME"; then
    echo "  Stopping existing instance…"
    pkill -x "$APP_NAME" || true
    sleep 0.5
fi

# Create bundle structure only if it doesn't exist yet.
mkdir -p "$BUNDLE/Contents/MacOS"

# Write Info.plist only if missing
if [ ! -f "$BUNDLE/Contents/Info.plist" ]; then
cat > "$BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.memo.app</string>
    <key>CFBundleName</key>
    <string>Memo</string>
    <key>CFBundleExecutable</key>
    <string>Memo</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Memo records your voice to transcribe it with the Whisper API.</string>
</dict>
</plist>
PLIST
fi

# Only copy + re-sign if the binary actually changed.
# Skipping re-sign preserves the CDHash → Accessibility TCC entry survives.
if cmp -s "$BINARY_SRC" "$BINARY_DEST" 2>/dev/null; then
    echo "  Binary unchanged — keeping existing signature (Accessibility stays granted)"
else
    echo "  Binary changed — updating and re-signing…"
    cp "$BINARY_SRC" "$BINARY_DEST"
    # Ad-hoc sign — required for `open` to work on modern macOS.
    codesign --force --sign - "$BUNDLE"
    echo "  ⚠️  If Accessibility was granted before, re-grant it once in:"
    echo "     System Settings → Privacy & Security → Accessibility → Memo"
fi

echo "Launching…"
open "$BUNDLE"

echo ""
echo "Done. Look for the mic icon in your menu bar."
echo ""
echo "  Hold ⌥ Space to record — you'll see a tiny waveform pill."
echo "  Release to transcribe."
