import XCTest
@testable import WhisperInput

@MainActor
final class AppStateTests: XCTestCase {

    func test_initialState_isIdle() {
        let state = AppState()
        XCTAssertEqual(state.recordingState, .idle)
        XCTAssertFalse(state.isRecording)
        XCTAssertFalse(state.isTranscribing)
        XCTAssertFalse(state.isEditing)
    }

    func test_stopRecording_whenIdle_isNoop() {
        let state = AppState()
        state.stopRecording()
        XCTAssertEqual(state.recordingState, .idle)
    }

    func test_reset_clearsTranscriptionAndError() {
        let state = AppState()
        state.transcribedText = "hello"
        state.errorMessage = "oops"
        state.recordingState = .editing
        state.reset()
        XCTAssertEqual(state.recordingState, .idle)
        XCTAssertEqual(state.transcribedText, "")
        XCTAssertNil(state.errorMessage)
        XCTAssertEqual(state.audioLevel, 0)
    }

    func test_confirmAndPaste_callsHandlerWithText_thenResets() {
        let state = AppState()
        var received: String?
        state.pasteHandler = { received = $0 }
        state.transcribedText = "hello world"
        state.recordingState = .editing
        state.confirmAndPaste()
        XCTAssertEqual(received, "hello world")
        XCTAssertEqual(state.recordingState, .idle)
        XCTAssertEqual(state.transcribedText, "")
    }

    func test_confirmAndPaste_withNoHandler_stillResets() {
        let state = AppState()
        state.transcribedText = "text"
        state.recordingState = .editing
        state.confirmAndPaste() // no crash, just resets
        XCTAssertEqual(state.recordingState, .idle)
    }

    func test_saveAndLoadPreferences_roundtrip() throws {
        let key = "openAIApiKey"
        let langKey = "selectedLanguage"
        let modeKey = "recordingMode"
        defer {
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.removeObject(forKey: langKey)
            UserDefaults.standard.removeObject(forKey: modeKey)
        }

        let state = AppState()
        state.openAIApiKey = "sk-test-123"
        state.selectedLanguage = "fr"
        state.recordingMode = .toggle
        state.savePreferences()

        let loaded = AppState()
        XCTAssertEqual(loaded.openAIApiKey, "sk-test-123")
        XCTAssertEqual(loaded.selectedLanguage, "fr")
        XCTAssertEqual(loaded.recordingMode, .toggle)
    }
}

final class RecordingStateTests: XCTestCase {

    func test_menuBarIconName_allCases() {
        XCTAssertEqual(RecordingState.idle.menuBarIconName,         "mic.circle")
        XCTAssertEqual(RecordingState.recording.menuBarIconName,    "mic.circle.fill")
        XCTAssertEqual(RecordingState.transcribing.menuBarIconName, "waveform.circle")
        XCTAssertEqual(RecordingState.editing.menuBarIconName,      "checkmark.circle")
    }
}
