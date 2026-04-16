import Foundation

/// Persists the last 50 transcription entries to UserDefaults.
final class HistoryStore: ObservableObject {
    private static let defaultsKey = "transcription_history"
    private static let maxEntries = 50

    /// All stored entries, most recent first.
    @Published private(set) var entries: [TranscriptionEntry] = []

    init() {
        entries = Self.load()
    }

    // MARK: - Public API

    /// Appends a new entry (trimming to 50 entries) and persists immediately.
    func add(_ text: String, language: String?) {
        let entry = TranscriptionEntry(text: text, language: language)
        var updated = [entry] + entries
        if updated.count > Self.maxEntries {
            updated = Array(updated.prefix(Self.maxEntries))
        }
        entries = updated
        save(entries)
    }

    /// Removes all entries.
    func clear() {
        entries = []
        UserDefaults.standard.removeObject(forKey: Self.defaultsKey)
    }

    // MARK: - Private persistence

    private static func load() -> [TranscriptionEntry] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return [] }
        return (try? JSONDecoder().decode([TranscriptionEntry].self, from: data)) ?? []
    }

    private func save(_ entries: [TranscriptionEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
