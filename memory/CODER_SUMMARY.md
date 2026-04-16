# Coder Summary — 2026-04-16

## What was created / modified

### New files

| File | Description |
|------|-------------|
| `Sources/Memo/Models/TranscriptionEntry.swift` | `Identifiable`, `Codable`, `Equatable` struct with `id: UUID`, `text: String`, `date: Date`, `language: String?`. |
| `Sources/Memo/Services/HistoryStore.swift` | `ObservableObject` that persists up to 50 `TranscriptionEntry` values in `UserDefaults` under the key `transcription_history`. Exposes `add(_:language:)`, `clear()`, and `@Published entries`. |
| `Sources/Memo/Views/HistoryView.swift` | SwiftUI view (440 × 520 pt) with a search bar, a scrollable `List` of rows (each showing date + text excerpt plus a "Copy" button), and a "Clear History" footer button. |
| `Tests/MemoTests/HistoryStoreTests.swift` | 7 unit tests covering initial state, `add` ordering, language storage, 50-entry cap, cross-instance persistence, `clear` in-memory, and `clear` persistence. |

### Modified files

| File | Change |
|------|--------|
| `Sources/Memo/Models/AppState.swift` | Added `let historyStore: HistoryStore = HistoryStore()` property; calls `historyStore.add(text, language: language)` after every successful transcription. |
| `Sources/Memo/MemoApp.swift` | `AppMenuView` wires an `openHistory` closure to a "History…" `Button`; `MenuBarExtra` passes `openHistory: { appDelegate.openHistoryWindow() }`. |
| `Sources/Memo/AppDelegate.swift` | Added `private var historyWindow: NSWindow?` and `openHistoryWindow()` which creates (or re-focuses) an `NSWindow` hosting `HistoryView`. |

## Design decisions

- **UserDefaults + JSONEncoder** — no external dependencies; 50 entries × ~500 bytes ≈ 25 KB, well within the NSUserDefaults overhead threshold.
- **`HistoryStore` is a separate `ObservableObject`** owned by `AppState` so that `HistoryView` can observe it directly without going through the larger `AppState` publish chain.
- **Single `NSWindow` for history** — `historyWindow` is reused (`isReleasedWhenClosed = false`) so the search state and scroll position survive window close/reopen within a session.
- **Local search filter** — performed synchronously on the already-loaded `entries` array; no async work, no network.

## Build result

Swift toolchain is not installed in this Linux CI environment (`swift: command not found`). The implementation was validated by:

- Cross-checking every symbol reference against existing source files.
- Confirming `HistoryStore`, `TranscriptionEntry`, and `HistoryView` match the API surface called by `AppState`, `AppDelegate`, and `MemoApp`.
- Reviewing all existing tests to confirm no regressions are introduced (no changed APIs, only additive changes).
