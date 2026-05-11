# Memo

[![CI](https://github.com/amadoug2g/whisper-input/actions/workflows/ci.yml/badge.svg)](https://github.com/amadoug2g/whisper-input/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/amadoug2g/whisper-input?label=release)](https://github.com/amadoug2g/whisper-input/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-13%2B-blue)](https://github.com/amadoug2g/whisper-input)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Application macOS de dictee vocale, invisible dans le Dock, qui vit dans la barre de menus. Parlez, relisez, collez : trois gestes, zero friction.

Memo enregistre votre voix via un raccourci global, envoie l'audio a l'API OpenAI Whisper, puis colle le texte transcrit dans l'application de votre choix.

**Landing page :** [amadoug2g.github.io/whisper-input](https://amadoug2g.github.io/whisper-input)

## Telecharger

**[Telecharger Memo v1.0 (DMG)](https://github.com/amadoug2g/whisper-input/releases/latest/download/Memo-v1.0.dmg)**

1. Ouvrez le DMG
2. Glissez **Memo** dans le dossier Applications
3. Lancez Memo depuis Spotlight ou Applications
4. Collez votre cle API OpenAI dans les preferences

> Requiert macOS 13 Ventura ou ulterieur et une [cle API OpenAI](https://platform.openai.com/api-keys).

## Comment ca marche

```
[Raccourci global ⌥ Espace]
        │
        ▼
[Enregistrement audio]
        │
        ▼
[Envoi a l'API Whisper]
        │
        ▼
[Panneau flottant : relecture et correction]
        │
        ▼
[⌘Entree → coller dans le champ actif]
```

## Fonctionnalites

- **Raccourci global** (⌥ Espace par defaut, configurable dans les preferences)
- **Panneau flottant minimaliste** qui apparait au-dessus de votre contexte actuel
- **Transcription modifiable** : corrigez avant de coller, ou activez le collage automatique
- **Multilingue** : detection automatique ou langue fixee manuellement (18 langues)
- **Barre de menus uniquement** : aucune presence dans le Dock
- **Mode collage automatique** : le texte est colle directement apres la transcription, sans etape de relecture
- **Raccourci personnalisable** : changez la combinaison de touches dans les preferences
- **Session reseau ephemere** : aucune donnee audio n'est stockee sur le disque
- **Cle API dans le Trousseau** : stockage securise via le Keychain macOS
- **Verification de cle API** : testez votre cle directement depuis les preferences
- **Accessibilite** : compatible VoiceOver, annonces d'etat, prise en charge de Reduce Motion

## Pile technique

| Couche | Choix | Raison |
|---|---|---|
| Langage | Swift 5.9 | Performances natives, integration AppKit/SwiftUI |
| Interface | SwiftUI + MenuBarExtra | Declaratif, iteration rapide |
| Panneau flottant | AppKit (NSPanel) | Controle total du comportement de la fenetre |
| Raccourci global | Carbon Event Manager | API la plus fiable pour les raccourcis globaux macOS |
| Audio | AVFoundation (AVAudioRecorder) | Simple, integre, sans dependances |
| Transcription | API OpenAI Whisper (gpt-4o-mini-transcribe) | Precision de pointe, multilingue |
| Collage | CGEvent (simulation Cmd+V) | Fonctionne dans toutes les applications |
| Stockage securise | Keychain Services | Cle API protegee par le systeme |

## Structure du projet

```
Sources/Memo/
├── MemoApp.swift              # Point d'entree, MenuBarExtra, menu
├── AppDelegate.swift          # Raccourci, orchestration du collage
├── Models/
│   └── AppState.swift         # ObservableObject central (etat, preferences)
├── Views/
│   ├── TranscriptionView.swift  # Panneau flottant (editeur, bouton coller)
│   └── SettingsView.swift       # Cle API, langue, raccourci, comportement
└── Services/
    ├── AudioRecorder.swift      # AVAudioRecorder (mono m4a 16 kHz)
    ├── WhisperService.swift     # POST multipart vers /v1/audio/transcriptions
    ├── HotkeyManager.swift      # Raccourci global Carbon
    ├── PanelController.swift    # Cycle de vie du panneau flottant
    ├── PreferencesStore.swift   # Persistance UserDefaults + Keychain
    ├── KeychainService.swift    # Lecture/ecriture Keychain
    └── PasteService.swift       # Presse-papiers + simulation CGEvent
```

## Installation depuis les sources

### Prerequis

- macOS 13 Ventura ou ulterieur
- Xcode 15+ (ou Swift 5.9 en ligne de commande)
- Une [cle API OpenAI](https://platform.openai.com/api-keys)

### Lancer en une commande

```bash
chmod +x run.sh && ./run.sh
```

Ou via le Makefile :

```bash
make dev      # lancer en mode debug
make test     # executer les tests
make app      # construire le .app en release
make dmg      # construire le DMG (Memo-v1.0.dmg)
make install  # copier dans /Applications
```

### Premier lancement

1. Cliquez sur l'icone micro dans la barre de menus
2. Ouvrez les preferences, collez votre cle API OpenAI, cliquez "Save"
3. Maintenez ⌥ Espace pour enregistrer, relachez pour transcrire
4. L'autorisation Accessibilite sera demandee la premiere fois que vous collez

### Permissions requises

- **Microphone** : pour enregistrer l'audio (demande automatique au premier enregistrement)
- **Accessibilite** : pour le raccourci global et le collage via simulation clavier (demande contextuelle, uniquement au moment du collage)

## Tests

```bash
make test
```

46 tests couvrant la machine d'etats, le cycle enregistrement/transcription/collage, les preferences, le service Whisper et les mocks injectables.

## Feuille de route

### Fait

- [x] Stockage de la cle API dans le Trousseau (Keychain)
- [x] Raccourci personnalisable via l'interface
- [x] Indicateur de niveau audio (barre de frequences animee)
- [x] Mode collage automatique (sans panneau de relecture)
- [x] Session URLSession ephemere avec delai d'expiration de 30 secondes
- [x] Verification de validite de la cle API depuis les preferences
- [x] Architecture testable (protocoles AudioRecording, Transcribing)
- [x] Pre-chauffage de l'enregistreur (latence quasi nulle au demarrage)
- [x] Entitlements sandbox, PrivacyInfo.xcprivacy
- [x] Infrastructure de localisation (en.lproj)
- [x] Makefile avec cibles dev/test/app/dmg/install/clean
- [x] Script DMG + workflow GitHub Release automatise sur tag `v*`
- [x] Landing page GitHub Pages (`docs/index.html`)

### A venir

- [ ] Support des prefixes de prompt (ex. : "Reformule en francais soutenu")
- [ ] Modele Whisper local en fallback (whisper.cpp ou WhisperKit) pour une utilisation hors ligne
- [ ] Historique des transcriptions recentes avec recherche
- [ ] Themes visuels (clair, sombre, systeme)
- [ ] Localisation francaise complete de l'interface

## Licence

MIT
