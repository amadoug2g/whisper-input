import Foundation

// MARK: - Protocol

/// Abstraction over the history store, allowing injection of mock implementations in tests.
protocol HistoryStoring: AnyObject {
    /// All entries, ordered by date descending (newest first).
    var entries: [TranscriptionEntry] { get }

    /// Adds an entry, evicting the oldest when the 50-entry cap is exceeded.
    func add(entry: TranscriptionEntry)

    /// Removes all entries.
    func clear()

    /// Returns entries whose text contains `query` (case- and diacritic-insensitive).
    func search(query: String) -> [TranscriptionEntry]
}

// MARK: - Implementation

/// Persists up to 50 `TranscriptionEntry` values in `UserDefaults`.
final class HistoryStore: HistoryStoring {

    static let defaultsKey = "transcriptionHistory"
    static let maxEntries = 50

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - HistoryStoring

    var entries: [TranscriptionEntry] {
        load().sorted { $0.date > $1.date }
    }

    func add(entry: TranscriptionEntry) {
        var current = load()
        current.append(entry)

        // Evict oldest entries when the cap is exceeded.
        if current.count > Self.maxEntries {
            current.sort { $0.date < $1.date } // oldest first
            current.removeFirst(current.count - Self.maxEntries)
        }

        persist(current)
    }

    func clear() {
        defaults.removeObject(forKey: Self.defaultsKey)
    }

    func search(query: String) -> [TranscriptionEntry] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return entries
        }
        return entries.filter {
            $0.text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    // MARK: - Private persistence

    private func load() -> [TranscriptionEntry] {
        guard let data = defaults.data(forKey: Self.defaultsKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([TranscriptionEntry].self, from: data)) ?? []
    }

    private func persist(_ entries: [TranscriptionEntry]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(entries) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }
}
