# Memo — Claude Code Project Guide

## What is Memo?

Memo is a macOS menu-bar-only voice dictation app. Global shortcut (⌥ Space) → records audio → sends to OpenAI Whisper API → shows floating panel for review → pastes text into any app via ⌘V simulation.

**Goal:** Publish before April 30, 2026 — GitHub Release (DMG) + GitHub Pages landing page.

---

## Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 5.9 |
| UI | SwiftUI + MenuBarExtra + AppKit NSPanel |
| Global hotkey | Carbon Event Manager |
| Audio | AVFoundation (AVAudioRecorder, m4a, 16 kHz mono) |
| Transcription | OpenAI Whisper API (`gpt-4o-mini-transcribe`) |
| Paste | CGEvent keyboard simulation (⌘V) |
| Secure storage | macOS Keychain Services |
| Build | Swift Package Manager + Makefile |

---

## Project Structure

```
Sources/Memo/
├── MemoApp.swift              # SwiftUI entry, MenuBarExtra scene
├── AppDelegate.swift          # Hotkey wiring, paste orchestration
├── Models/
│   └── AppState.swift         # Central @MainActor ObservableObject
├── Views/
│   ├── TranscriptionView.swift  # Floating edit panel
│   └── SettingsView.swift       # API key, language, hotkey prefs
└── Services/
    ├── AudioRecorder.swift      # AVAudioRecorder wrapper (protocol: AudioRecording)
    ├── WhisperService.swift     # Whisper API client (protocol: Transcribing)
    ├── HotkeyManager.swift      # Carbon global shortcut manager
    ├── PanelController.swift    # NSPanel lifecycle
    ├── PreferencesStore.swift   # UserDefaults + Keychain persistence
    ├── KeychainService.swift    # Keychain read/write/delete
    └── PasteService.swift       # Clipboard + CGEvent paste

Sources/MemoMain/
└── main.swift                 # Entry point: MemoApp.main()

Tests/MemoTests/               # 46 tests
├── AppStateTests.swift
├── DeploymentTests.swift
├── PanelControllerTests.swift
├── PreferencesStoreTests.swift
├── WhisperServiceTests.swift
└── Mocks.swift
```

---

## Core State Machine

```
idle → recording → transcribing → editing → idle
                              └→ error(String) → idle (auto after 4s)
```

Transitions enforced in AppState.swift. All state changes are `@MainActor`.

---

## Build Commands

```bash
make test      # swift test — run all 46 tests
make app       # release build → scripts/package-app.sh → Memo.app (ad-hoc signed)
make install   # copies Memo.app to /Applications
make dev       # swift run MemoMain (debug)
make clean     # rm -rf .build
./run.sh       # smart build + sign (preserves Accessibility TCC across restarts)
```

---

## Key Configuration

- **Bundle ID:** `com.memo.app`
- **Minimum macOS:** 13 Ventura
- **Entitlements:** sandbox, microphone (`audio-input`), network client
- **Privacy manifest:** `Sources/Memo/Resources/PrivacyInfo.xcprivacy`
- **Signing:** ad-hoc only (`codesign --force --sign -`)
- **No Dock presence:** `LSUIElement = true` in Info.plist

---

## Testing Patterns

- Protocol injection: `AudioRecording`, `Transcribing` for mockability
- `@MainActor` on all test classes that touch AppState
- Custom `waitForState()` helper (polls + yields, avoids RunLoop blocking)
- Mock classes in `Mocks.swift` with call counts and configurable results

---

## Commit Conventions

Use conventional commits:
- `feat:` new feature
- `fix:` bug fix
- `ci:` CI/CD changes
- `docs:` documentation
- `refactor:` code restructure (no behavior change)
- `test:` test additions/fixes

---

## Agent Workflow

See `memory/` directory:
- `DAILY_GOAL.md` — current day's implementation objective
- `ARCHITECTURE.md` — detailed architecture reference
- `ROADMAP.md` — release milestones and deadline
- `SESSION_LOG.md` — daily log of completed work
- `CODER_SUMMARY.md` — coder's output (read by reviewer)
- `REVIEWER_FEEDBACK.md` — reviewer's feedback when not LGTM

Branching: coder creates `feature/YYYYMMDD-<slug>`, reviewer opens PR to `main`.
