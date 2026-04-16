# Memo — Architecture Reference

## Vue d'ensemble

Memo est une app macOS menu-bar-only. Aucune présence dans le Dock (`LSUIElement = true`). L'utilisateur interagit via un raccourci global et un panneau flottant NSPanel.

**Flow principal :**
```
[Raccourci ⌥ Espace]
    → AppDelegate.hotkeyPressed()
    → AppState.startRecording()
    → AudioRecorder.startRecording()
    → [Utilisateur relâche]
    → AppState.stopRecording()
    → WhisperService.transcribe(audioURL)
    → AppState → .editing (panneau flottant) ou auto-paste
    → PasteService.paste(text)
```

---

## State Machine centrale

**Fichier :** `Sources/Memo/Models/AppState.swift`

```swift
enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case editing
    case error(String)
}
```

**Transitions valides :**
- `idle` → `recording` : hotkey pressée
- `recording` → `transcribing` : hotkey relâchée (durée > 500ms)
- `recording` → `idle` : trop court (< 500ms), annulé
- `transcribing` → `editing` : transcription réussie
- `transcribing` → `error` : API échoue
- `editing` → `idle` : ⌘↩ (paste) ou Esc (annuler)
- `error` → `idle` : auto-dismiss après 4s ou Esc

**`AppState` est `@MainActor ObservableObject`.**

---

## Services Layer

Tous les services ont des **protocoles** pour l'injectabilité (testabilité).

### AudioRecorder (`AudioRecording` protocol)
**Fichier :** `Sources/Memo/Services/AudioRecorder.swift`
- `AVAudioRecorder`, format AAC, 16 kHz, mono
- Pré-chauffe au démarrage pour réduire la latence
- Publie le niveau audio (50ms intervals) via `audioLevelPublisher`
- Sauvegarde dans `FileManager.temporaryDirectory`

### WhisperService (`Transcribing` protocol)
**Fichier :** `Sources/Memo/Services/WhisperService.swift`
- Endpoint : `https://api.openai.com/v1/audio/transcriptions`
- Modèle : `gpt-4o-mini-transcribe`
- URLSession éphémère (pas de cache disque, pas de cookies)
- Timeout : 30s requête, 90s ressource
- Multipart form-data avec le fichier audio et la langue optionnelle

### HotkeyManager
**Fichier :** `Sources/Memo/Services/HotkeyManager.swift`
- Carbon Event Manager (API la plus fiable pour les raccourcis globaux)
- Enregistre `kEventHotKeyPressed` et `kEventHotKeyReleased`
- Défaut : ⌥ Espace (keyCode 49, modifier 2048)
- Détecte les conflits de touches

### PasteService
**Fichier :** `Sources/Memo/Services/PasteService.swift`
- Sauvegarde le clipboard précédent, écrit le texte, simule ⌘V via CGEvent
- Restaure le clipboard après 500ms
- Requiert `AXIsProcessTrusted()` (permission Accessibility)

### KeychainService
**Fichier :** `Sources/Memo/Services/KeychainService.swift`
- Service : `"com.memo.app"`, compte : `"openAIApiKey"`
- `kSecAttrAccessibleWhenUnlocked`
- Opérations : `save()`, `load()`, `delete()`

### PreferencesStore
**Fichier :** `Sources/Memo/Services/PreferencesStore.swift`
- UserDefaults : langue, mode enregistrement, auto-paste, codes hotkey
- Keychain : clé API (chargement différé, ~10-50ms)
- Fast load (launch) vs full load (settings screen)

### PanelController
**Fichier :** `Sources/Memo/Services/PanelController.swift`
- Gère le cycle de vie du NSPanel flottant
- Mode compact (pill) pendant l'enregistrement/transcription
- Mode plein pendant l'édition

---

## Vues

### TranscriptionView
**Fichier :** `Sources/Memo/Views/TranscriptionView.swift`
- NSPanel flottant au-dessus de toutes les fenêtres
- Compact pill (recording/transcribing) → full (editing/error)
- ⌘↩ pour coller, Esc pour annuler

### SettingsView
**Fichier :** `Sources/Memo/Views/SettingsView.swift`
- Clé API (avec test), langue (18 langues), mode enregistrement, hotkey personnalisé
- Auto-paste toggle

---

## Configuration Build

```
Package.swift
├── Target: Memo (library) — toutes les sources + ressources
├── Target: MemoMain (executable) — main.swift only
└── Target: MemoTests (tests)
```

**Entitlements** (`Memo.entitlements`) :
- `com.apple.security.app-sandbox: true`
- `com.apple.security.device.audio-input: true`
- `com.apple.security.network.client: true`

**Signing :** ad-hoc uniquement (`codesign --force --sign -`)

---

## Tests

**Fichiers :** `Tests/MemoTests/`
- 46 tests au total
- Pattern : `@MainActor`, `waitForState()` helper, mocks injectés
- Mocks : `MockAudioRecorder`, `MockTranscriber`, `MockPasteOrchestrator` dans `Mocks.swift`

```bash
make test    # swift test
```

---

## Chemins critiques

| Fichier | Rôle |
|---------|------|
| `Sources/Memo/Models/AppState.swift` | State machine centrale |
| `Sources/Memo/AppDelegate.swift` | Orchestration hotkey + paste |
| `Sources/Memo/MemoApp.swift` | Entry point SwiftUI |
| `Sources/Memo/Services/WhisperService.swift` | API Whisper |
| `Sources/Memo/Services/AudioRecorder.swift` | Capture audio |
| `Sources/Memo/Services/HotkeyManager.swift` | Raccourci global |
| `Sources/Memo/Services/PasteService.swift` | Clipboard + CGEvent |
| `Memo.entitlements` | Permissions sandbox |
| `Makefile` | Build targets |
| `scripts/package-app.sh` | Packaging .app |
