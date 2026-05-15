import XCTest
@testable import Memo

final class HistoryStoreTests: XCTestCase {

    private let testDefaultsKey = "transcriptionHistory_test"
    private var testDefaults: UserDefaults!
    private var store: HistoryStore!

    override func setUp() {
        super.setUp()
        // Use a dedicated suite to isolate tests from UserDefaults.standard.
        testDefaults = UserDefaults(suiteName: "com.memo.tests.history")!
        testDefaults.removeObject(forKey: HistoryStore.defaultsKey)
        store = HistoryStore(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removeObject(forKey: HistoryStore.defaultsKey)
        testDefaults.removeSuite(named: "com.memo.tests.history")
        store = nil
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - test_addEntry_persistsToUserDefaults

    func test_addEntry_persistsToUserDefaults() {
        let entry = TranscriptionEntry(text: "Hello world", language: "en")
        store.add(entry: entry)

        // Verify raw data was written to UserDefaults.
        XCTAssertNotNil(testDefaults.data(forKey: HistoryStore.defaultsKey),
                        "Entry should be persisted to UserDefaults")
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.text, "Hello world")
    }

    // MARK: - test_entries_orderedByDateDescending

    func test_entries_orderedByDateDescending() {
        let now = Date()
        let older = TranscriptionEntry(
            id: UUID(), text: "Older", date: now.addingTimeInterval(-120), language: nil)
        let newer = TranscriptionEntry(
            id: UUID(), text: "Newer", date: now, language: nil)
        let middle = TranscriptionEntry(
            id: UUID(), text: "Middle", date: now.addingTimeInterval(-60), language: nil)

        store.add(entry: older)
        store.add(entry: middle)
        store.add(entry: newer)

        let result = store.entries
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].text, "Newer",  "Newest must be first")
        XCTAssertEqual(result[1].text, "Middle", "Middle must be second")
        XCTAssertEqual(result[2].text, "Older",  "Oldest must be last")
    }

    // MARK: - test_maxEntries_removesOldest

    func test_maxEntries_removesOldest() {
        let base = Date()
        // Add maxEntries + 1 items; the oldest should be evicted.
        for index in 0...HistoryStore.maxEntries {
            let entry = TranscriptionEntry(
                id: UUID(),
                text: "Entry \(index)",
                date: base.addingTimeInterval(Double(index)),
                language: nil
            )
            store.add(entry: entry)
        }

        let result = store.entries
        XCTAssertEqual(result.count, HistoryStore.maxEntries,
                       "Store must cap at \(HistoryStore.maxEntries) entries")

        // The oldest entry (index 0) must have been evicted.
        let texts = result.map(\.text)
        XCTAssertFalse(texts.contains("Entry 0"), "Oldest entry must be evicted")
        XCTAssertTrue(texts.contains("Entry \(HistoryStore.maxEntries)"),
                      "Newest entry must be retained")
    }

    // MARK: - test_clear_removesAll

    func test_clear_removesAll() {
        store.add(entry: TranscriptionEntry(text: "First",  language: nil))
        store.add(entry: TranscriptionEntry(text: "Second", language: nil))
        XCTAssertEqual(store.entries.count, 2)

        store.clear()

        XCTAssertEqual(store.entries.count, 0, "clear() must remove all entries")
        XCTAssertNil(testDefaults.data(forKey: HistoryStore.defaultsKey),
                     "UserDefaults key must be removed after clear()")
    }

    // MARK: - test_search_filtersCorrectly

    func test_search_filtersCorrectly() {
        store.add(entry: TranscriptionEntry(text: "Hello world",    language: nil))
        store.add(entry: TranscriptionEntry(text: "Bonjour monde",  language: "fr"))
        store.add(entry: TranscriptionEntry(text: "Swift testing",  language: "en"))

        // Case-insensitive match
        let helloResults = store.search(query: "hello")
        XCTAssertEqual(helloResults.count, 1)
        XCTAssertEqual(helloResults.first?.text, "Hello world")

        // Partial match
        let swiftResults = store.search(query: "Swift")
        XCTAssertEqual(swiftResults.count, 1)
        XCTAssertEqual(swiftResults.first?.text, "Swift testing")

        // Empty query returns all
        let allResults = store.search(query: "")
        XCTAssertEqual(allResults.count, 3)

        // Whitespace-only query returns all
        let whitespaceResults = store.search(query: "   ")
        XCTAssertEqual(whitespaceResults.count, 3)

        // No match returns empty
        let noResults = store.search(query: "Zzz")
        XCTAssertEqual(noResults.count, 0)
    }

    // MARK: - test_search_isDiacriticInsensitive

    func test_search_isDiacriticInsensitive() {
        store.add(entry: TranscriptionEntry(text: "café au lait", language: "fr"))

        let results = store.search(query: "cafe")
        XCTAssertEqual(results.count, 1,
                       "Search must be diacritic-insensitive — 'cafe' should match 'café'")
    }
}

// MARK: - MockHistoryStore (for use in AppState tests)

final class MockHistoryStore: HistoryStoring {
    private(set) var addedEntries: [TranscriptionEntry] = []
    private(set) var clearCallCount = 0

    var entries: [TranscriptionEntry] { addedEntries }

    func add(entry: TranscriptionEntry) {
        addedEntries.append(entry)
    }

    func clear() {
        addedEntries.removeAll()
        clearCallCount += 1
    }

    func search(query: String) -> [TranscriptionEntry] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return entries }
        return entries.filter {
            $0.text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}
