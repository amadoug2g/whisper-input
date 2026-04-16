# Objectif du jour — 2026-04-16

## Fonctionnalité : Historique des transcriptions récentes

Implémenter un historique des transcriptions récentes persistant entre les sessions, accessible depuis la barre de menus.

### Exigences

1. **Modèle `TranscriptionEntry`** (dans `Models/`)
   - `id: UUID`
   - `text: String`
   - `date: Date`
   - `language: String?`

2. **Service `HistoryStore`** (dans `Services/`)
   - Stocke jusqu'à **50 entrées** dans `UserDefaults` (clé `transcription_history`)
   - `func add(_ text: String, language: String?)`
   - `func clear()`
   - `var entries: [TranscriptionEntry]` (du plus récent au plus ancien)

3. **Vue `HistoryView`** (dans `Views/`)
   - Liste scrollable des entrées (date + extrait du texte)
   - Bouton "Copier" sur chaque ligne (copie dans le presse-papiers)
   - Bouton "Effacer l'historique" en bas
   - Barre de recherche (filtre local, pas de réseau)

4. **Intégration dans `AppState`**
   - `AppState` détient une instance de `HistoryStore`
   - Après chaque transcription réussie, appeler `historyStore.add(...)`

5. **Intégration dans le menu** (`MemoApp.swift`)
   - Nouvelle entrée "Historique" dans le menu MenuBarExtra qui ouvre `HistoryView` dans une fenêtre dédiée

### Contraintes
- Pas de dépendances externes
- Compatible Swift 5.9 / macOS 13
- Les tests existants ne doivent pas être cassés
- Ajouter au moins un test unitaire pour `HistoryStore`

### Fichiers à créer / modifier
- `Sources/Memo/Models/TranscriptionEntry.swift` (nouveau)
- `Sources/Memo/Services/HistoryStore.swift` (nouveau)
- `Sources/Memo/Views/HistoryView.swift` (nouveau)
- `Sources/Memo/Models/AppState.swift` (modifier)
- `Sources/Memo/MemoApp.swift` (modifier)
- `Tests/MemoTests/HistoryStoreTests.swift` (nouveau)
