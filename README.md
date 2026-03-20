# WhisperInput

A lightweight macOS menubar app that lets you dictate into any text field — system-wide.

Press a global hotkey → speak → review/edit the transcription → paste. Done.

## How it works

```
[Global Hotkey ⌥Space]
        │
        ▼
[Record audio]  ──────────────────────────────────────────┐
        │                                                  │
        ▼                                                  │
[Send to OpenAI Whisper API]                               │
        │                                                  │
        ▼                                               (cancel)
[Floating panel: review & edit transcription]              │
        │                                                  │
        ▼                                                  │
[⌘Return → paste into previously active field] ◄──────────┘
```

## Features

- **Global hotkey** (⌥ Space by default) — works from any app
- **Minimal floating panel** — appears over your current context
- **Editable transcription** — fix mistakes before pasting
- **Multi-language** — auto-detect or pin to a specific language
- **No local model** — uses OpenAI Whisper API (fast, accurate, low binary size)
- **Menubar-only** — stays out of your Dock and your way

## Tech stack

| Layer | Choice | Why |
|---|---|---|
| Language | Swift 5.9 | Native performance, best AppKit/SwiftUI integration |
| UI | SwiftUI | Declarative, fast to iterate |
| Menubar / Panel | AppKit (`NSStatusItem`, `NSPanel`) | Full control over floating window behavior |
| Global hotkey | Carbon Event Manager | Most reliable global hotkey API on macOS |
| Audio | AVFoundation (`AVAudioRecorder`) | Simple, built-in, no dependencies |
| Transcription | OpenAI Whisper API (`whisper-1`) | Best-in-class accuracy, multilingual |
| Paste | CGEvent Cmd+V simulation | Works across all apps |

## Project structure

```
Sources/WhisperInput/
├── WhisperInputApp.swift       # @main entry point
├── AppDelegate.swift           # Menubar icon, hotkey wiring, panel management
├── Models/
│   └── AppState.swift          # Central ObservableObject (recording state, prefs)
├── Views/
│   ├── TranscriptionView.swift # Floating panel UI (editor + paste button)
│   └── SettingsView.swift      # API key, language, hotkey settings
└── Services/
    ├── AudioRecorder.swift     # AVAudioRecorder wrapper (16 kHz mono m4a)
    ├── WhisperService.swift    # Multipart POST to OpenAI /v1/audio/transcriptions
    ├── HotkeyManager.swift     # Carbon global hotkey registration
    └── PasteService.swift      # Pasteboard write + CGEvent Cmd+V simulation
```

## Setup

### Prerequisites

- macOS 13 Ventura or later
- Xcode 15+
- An [OpenAI API key](https://platform.openai.com/api-keys)

### Running the app

1. **Open in Xcode**

   ```bash
   # Option A: open the Swift package directly
   open Package.swift

   # Option B: create a new Xcode project
   # File > New > Project > macOS > App
   # Add the files from Sources/WhisperInput/ to the project
   ```

2. **Configure entitlements** (required for microphone + network):

   In Xcode, add a `.entitlements` file with:
   ```xml
   <key>com.apple.security.device.audio-input</key>
   <true/>
   <key>com.apple.security.network.client</key>
   <true/>
   ```

   And in `Info.plist`:
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>WhisperInput needs your microphone to record audio for transcription.</string>
   ```

3. **Set your API key**

   Launch the app → click the menubar icon → Settings → paste your `OPENAI_API_KEY`.

   Alternatively, set it before building (for development):
   ```bash
   export OPENAI_API_KEY="sk-..."
   ```

4. **Grant permissions** (first launch)

   - **Microphone**: System Settings > Privacy & Security > Microphone
   - **Accessibility** (for global hotkey + paste simulation): System Settings > Privacy & Security > Accessibility

### Permissions note

The global hotkey and CGEvent paste require **Accessibility** permission. The app will prompt you on first use. Without it, the hotkey won't fire outside the app and paste simulation won't work.

## Roadmap

- [ ] Keychain storage for API key (instead of UserDefaults)
- [ ] Customizable hotkey via UI
- [ ] Visual audio level meter during recording
- [ ] Prompt prefix support (e.g. "Always use formal English")
- [ ] Local Whisper model fallback (via whisper.cpp / WhisperKit) for offline use
- [ ] History of recent transcriptions

## License

MIT
