import XCTest
@testable import Memo

final class HistoryStoreTests: XCTestCase {

    private let defaultsKey = "transcription_history"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }

    // MARK: - Initial state

    func test_initialEntries_isEmpty_whenNothingStored() {
        let store = HistoryStore()
        XCTAssertTrue(store.entries.isEmpty)
    }

    // MARK: - Add

    func test_add_appendsEntryAtFront() {
        let store = HistoryStore()
        store.add("Hello", language: nil)
        XCTAssertEqual(store.entries.count, 1)
        XCTAssertEqual(store.entries.first?.text, "Hello")
    }

    func test_add_newerEntryIsFirst() {
        let store = HistoryStore()
        store.add("First", language: nil)
        store.add("Second", language: nil)
        XCTAssertEqual(store.entries.first?.text, "Second")
        XCTAssertEqual(store.entries.last?.text, "First")
    }

    func test_add_storesLanguage() {
        let store = HistoryStore()
        store.add("Bonjour", language: "fr")
        XCTAssertEqual(store.entries.first?.language, "fr")
    }

    func test_add_capsAt50Entries() {
        let store = HistoryStore()
        for i in 1...55 {
            store.add("Entry \(i)", language: nil)
        }
        XCTAssertEqual(store.entries.count, 50)
        // Most recent entry should be "Entry 55"
        XCTAssertEqual(store.entries.first?.text, "Entry 55")
        // Oldest kept entry should be "Entry 6" (55 - 50 + 1)
        XCTAssertEqual(store.entries.last?.text, "Entry 6")
    }

    // MARK: - Persistence

    func test_entries_persistAcrossInstances() {
        let store1 = HistoryStore()
        store1.add("Persisted text", language: "en")

        let store2 = HistoryStore()
        XCTAssertEqual(store2.entries.count, 1)
        XCTAssertEqual(store2.entries.first?.text, "Persisted text")
        XCTAssertEqual(store2.entries.first?.language, "en")
    }

    // MARK: - Clear

    func test_clear_removesAllEntries() {
        let store = HistoryStore()
        store.add("One", language: nil)
        store.add("Two", language: nil)
        store.clear()
        XCTAssertTrue(store.entries.isEmpty)
    }

    func test_clear_removesPersistedData() {
        let store = HistoryStore()
        store.add("Saved", language: nil)
        store.clear()

        let store2 = HistoryStore()
        XCTAssertTrue(store2.entries.isEmpty)
    }
}
