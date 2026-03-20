#!/bin/bash
# Builds WhisperInput and launches it as a proper .app bundle.
# Ad-hoc signing lets macOS privacy dialogs work (mic, accessibility).
# Run: chmod +x run.sh && ./run.sh

set -euo pipefail

APP_NAME="WhisperInput"
BUNDLE="${APP_NAME}.app"
BINARY_SRC=".build/debug/WhisperInputMain"

echo "▶ Building…"
swift build 2>&1

# Kill any running instance so the new one can start cleanly
if pgrep -xq "$APP_NAME"; then
    echo "  Stopping existing instance…"
    pkill -x "$APP_NAME" || true
    sleep 0.5
fi

echo "▶ Assembling ${BUNDLE}…"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"

cp "$BINARY_SRC" "$BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.whisperinput.WhisperInput</string>
    <key>CFBundleName</key>
    <string>WhisperInput</string>
    <key>CFBundleExecutable</key>
    <string>WhisperInput</string>
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
    <string>WhisperInput records your voice to transcribe it with the Whisper API.</string>
</dict>
</plist>
PLIST

echo "▶ Signing (ad-hoc)…"
codesign --force --deep --sign - "$BUNDLE"

echo "▶ Launching…"
open "$BUNDLE"

echo ""
echo "✓ Done. Look for the mic icon (🎙) in your menu bar."
echo ""
echo "First-run checklist:"
echo "  1. Grant Accessibility when the system dialog appears"
echo "     (System Settings → Privacy → Accessibility → toggle WhisperInput on)"
echo "  2. Click the mic icon → Settings → paste your OpenAI API key → Save"
echo "  3. Hold ⌥ Space to record. Release to transcribe."
