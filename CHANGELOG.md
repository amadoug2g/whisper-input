# Changelog

All notable changes to Memo are documented in this file.

## [1.0] — 2026-04-28

### Initial Release

**Core Features**
- Global hotkey (Option+Space) to start/stop voice recording from any app
- Voice-to-text transcription via OpenAI Whisper API (`gpt-4o-mini-transcribe`)
- Floating review panel (compact pill during recording, full panel for editing)
- Auto-paste via CGEvent keyboard simulation (Cmd+V) into any app
- Push-to-talk and toggle recording modes
- Auto-paste mode (skip review panel)
- 18 supported languages with auto-detection

**Configuration**
- Customizable global hotkey
- OpenAI API key stored securely in macOS Keychain
- Language selection preference
- Auto-paste toggle

**Distribution**
- Menu-bar-only app (no Dock presence)
- macOS 13 Ventura+ support
- Ad-hoc signed DMG for direct download
- GitHub Release with automated CI/CD via GitHub Actions

**Technical**
- 46 unit tests
- Sandbox + entitlements (microphone, network)
- PrivacyInfo.xcprivacy
- Accessibility TCC preserved across restarts
