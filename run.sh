#!/bin/bash
# Builds Memo and launches it as a proper .app bundle.
#
# IMPORTANT: The dev build is NOT code-signed. This is intentional.
# macOS tracks Accessibility permission by PATH for unsigned binaries,
# which means the permission survives rebuilds. Ad-hoc signing creates
# a new code identity on every build, invalidating the permission each time.
# Use `make app` for a signed release build.
#
# Run: chmod +x run.sh && ./run.sh

set -euo pipefail

APP_NAME="Memo"
BUNDLE="${APP_NAME}.app"
BINARY_SRC=".build/debug/MemoMain"

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

# Update binary
cp "$BINARY_SRC" "$BUNDLE/Contents/MacOS/$APP_NAME"

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

# Strip any existing code signature so macOS tracks by path.
codesign --remove-signature "$BUNDLE" 2>/dev/null || true

echo "Launching…"
open "$BUNDLE"

echo ""
echo "Done. Look for the mic icon in your menu bar."
echo ""
echo "First run:"
echo "  1. Click the mic icon → Settings → paste your OpenAI API key → Done"
echo "  2. Hold ⌥ Space to record. Release to transcribe."
echo "  3. Accessibility permission is requested once on first paste."
echo "     Grant it and it persists across rebuilds."
