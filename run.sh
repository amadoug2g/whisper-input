#!/bin/bash
# Builds Memo and launches it as a proper .app bundle.
#
# IMPORTANT: The dev build is NOT code-signed. This is intentional.
# macOS tracks Accessibility permission by PATH for unsigned binaries,
# which means the permission survives rebuilds. Ad-hoc signing creates
# a new code identity on every build, invalidating the permission each time.
#
# NOTE: Unsigned apps CANNOT launch from /Applications (macOS blocks them
# with "Launchd job spawn failed", POSIX error 163). Dev builds launch
# from the project directory instead.
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

# Strip any existing code signature so macOS tracks Accessibility by path.
# This means permission persists across rebuilds without re-granting.
codesign --remove-signature "$BUNDLE" 2>/dev/null || true

echo "Launching…"
open "$BUNDLE"

echo ""
echo "Done. Look for the mic icon in your menu bar."
echo ""
echo "First run:"
echo "  1. Hold ⌥ Space to record — you should see a tiny waveform pill."
echo "  2. Release to transcribe."
echo "  3. On first paste, grant Accessibility when prompted (persists across rebuilds)."
echo ""
echo "Settings: click the mic icon in the menu bar → Settings."
