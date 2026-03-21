#!/bin/bash
# Builds Memo and launches it as a proper .app bundle.
#
# The build is ad-hoc signed (`codesign --force --sign -`). This is the
# minimum macOS requires to launch via `open`. Without any signature,
# modern macOS returns "Launchd job spawn failed" (POSIX error 163).
#
# Trade-off: ad-hoc signing changes the CDHash when the binary changes,
# which invalidates Accessibility (TCC) entries. The app handles this
# with a session-level cache, so you only re-grant once per session
# after a code change. Unchanged rebuilds keep the same CDHash.
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

# Ad-hoc sign — required for `open` to work on modern macOS.
# Without this: "Launchd job spawn failed" (POSIX error 163).
codesign --force --sign - "$BUNDLE"

echo "Launching…"
open "$BUNDLE"

echo ""
echo "Done. Look for the mic icon in your menu bar."
echo ""
echo "  Hold ⌥ Space to record — you'll see a tiny waveform pill."
echo "  Release to transcribe."
echo ""
echo "  Settings: click the mic icon → Settings"
echo "  (paste your OpenAI API key on first run)"
