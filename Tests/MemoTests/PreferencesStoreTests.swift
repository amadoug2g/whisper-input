import XCTest
@testable import Memo

final class PreferencesStoreTests: XCTestCase {

    private let langKey = "selectedLanguage"
    private let modeKey = "recordingMode"

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: langKey)
        UserDefaults.standard.removeObject(forKey: modeKey)
    }

    // MARK: - Defaults

    func test_loadFast_returnsDefaults_whenNothingStored() {
        let prefs = PreferencesStore.loadFast()
        XCTAssertEqual(prefs.language, "auto")
        XCTAssertEqual(prefs.recordingMode, .pushToTalk)
        XCTAssertEqual(prefs.apiKey, "", "loadFast must not touch Keychain")
    }

    // MARK: - Round-trip (UserDefaults only)

    func test_save_persistsLanguageAndMode() {
        let store = PreferencesStore(apiKey: "", language: "de", recordingMode: .toggle)
        store.save()

        let loaded = PreferencesStore.loadFast()
        XCTAssertEqual(loaded.language, "de")
        XCTAssertEqual(loaded.recordingMode, .toggle)
    }

    func test_save_overwritesPreviousValues() {
        PreferencesStore(apiKey: "", language: "fr", recordingMode: .pushToTalk).save()
        PreferencesStore(apiKey: "", language: "ja", recordingMode: .toggle).save()

        let loaded = PreferencesStore.loadFast()
        XCTAssertEqual(loaded.language, "ja")
        XCTAssertEqual(loaded.recordingMode, .toggle)
    }

    func test_load_includesLanguageAndMode() {
        PreferencesStore(apiKey: "", language: "es", recordingMode: .toggle).save()
        // `load()` = UserDefaults + Keychain; apiKey will be empty for a blank key save
        let loaded = PreferencesStore.load()
        XCTAssertEqual(loaded.language, "es")
        XCTAssertEqual(loaded.recordingMode, .toggle)
    }

    // MARK: - RecordingMode raw values

    func test_recordingMode_rawValues_roundTrip() {
        for mode in RecordingMode.allCases {
            let store = PreferencesStore(apiKey: "", language: "auto", recordingMode: mode)
            store.save()
            XCTAssertEqual(PreferencesStore.loadFast().recordingMode, mode)
        }
    }
}
