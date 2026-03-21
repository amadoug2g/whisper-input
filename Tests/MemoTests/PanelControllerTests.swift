import XCTest
@testable import Memo

@MainActor
final class PanelControllerTests: XCTestCase {

    private var appState: AppState!
    private var controller: PanelController!

    override func setUp() {
        super.setUp()
        appState = AppState(
            audioRecorder: MockAudioRecorder(),
            transcriber: MockTranscriber()
        )
        controller = PanelController(appState: appState)
    }

    override func tearDown() {
        controller.hide()
        controller = nil
        appState = nil
        super.tearDown()
    }

    // MARK: - Compact mode (recording / transcribing)

    func test_recording_createsCompactPanel() {
        // Mirror production: appState changes BEFORE updateFor is called
        appState.recordingState = .recording
        controller.updateFor(state: .recording)

        XCTAssertNotNil(controller.panel, "Panel should exist during recording")
        XCTAssertEqual(controller.isCompact, true, "Recording should use compact mode")

        let size = controller.panel!.frame.size
        XCTAssertLessThan(size.width, 200,
            "Compact pill width should be small, got \(size.width)")
        XCTAssertLessThan(size.height, 60,
            "Compact pill height should be small, got \(size.height)")
    }

    func test_transcribing_createsCompactPanel() {
        appState.recordingState = .transcribing
        controller.updateFor(state: .transcribing)

        XCTAssertNotNil(controller.panel, "Panel should exist during transcribing")
        XCTAssertEqual(controller.isCompact, true, "Transcribing should use compact mode")

        let size = controller.panel!.frame.size
        XCTAssertLessThan(size.width, 200,
            "Compact pill width should be small, got \(size.width)")
        XCTAssertLessThan(size.height, 60,
            "Compact pill height should be small, got \(size.height)")
    }

    // MARK: - Full mode (editing / error)

    func test_editing_createsFullPanel() {
        appState.transcribedText = "Test transcription"
        appState.recordingState = .editing
        controller.updateFor(state: .editing)

        XCTAssertNotNil(controller.panel, "Panel should exist during editing")
        XCTAssertEqual(controller.isCompact, false, "Editing should use full mode")

        let size = controller.panel!.frame.size
        XCTAssertGreaterThanOrEqual(size.width, 300,
            "Full panel should be wide, got \(size.width)")
        XCTAssertGreaterThan(size.height, 40,
            "Full panel should have height, got \(size.height)")
    }

    func test_error_createsFullPanel() {
        appState.recordingState = .error("Something went wrong")
        controller.updateFor(state: .error("Something went wrong"))

        XCTAssertNotNil(controller.panel, "Panel should exist during error")
        XCTAssertEqual(controller.isCompact, false, "Error should use full mode")
    }

    // MARK: - Idle destroys panel

    func test_idle_destroysPanel() {
        appState.recordingState = .recording
        controller.updateFor(state: .recording)
        XCTAssertNotNil(controller.panel)

        appState.recordingState = .idle
        controller.updateFor(state: .idle)
        XCTAssertNil(controller.panel, "Panel should be destroyed when idle")
        XCTAssertNil(controller.isCompact)
    }

    // MARK: - Mode switching rebuilds panel

    func test_compactToFull_rebuildsPanel() {
        appState.recordingState = .recording
        controller.updateFor(state: .recording)
        let compactPanel = controller.panel
        XCTAssertNotNil(compactPanel)

        appState.transcribedText = "Test"
        appState.recordingState = .editing
        controller.updateFor(state: .editing)
        let fullPanel = controller.panel
        XCTAssertNotNil(fullPanel)

        XCTAssertFalse(compactPanel === fullPanel,
            "Switching compact→full should rebuild the panel")
    }

    func test_fullToCompact_rebuildsPanel() {
        appState.transcribedText = "Test"
        appState.recordingState = .editing
        controller.updateFor(state: .editing)
        let fullPanel = controller.panel

        appState.recordingState = .recording
        controller.updateFor(state: .recording)
        let compactPanel = controller.panel

        XCTAssertFalse(fullPanel === compactPanel,
            "Switching full→compact should rebuild the panel")
    }

    func test_compactToCompact_reusesPanel() {
        appState.recordingState = .recording
        controller.updateFor(state: .recording)
        let panel1 = controller.panel

        appState.recordingState = .transcribing
        controller.updateFor(state: .transcribing)
        let panel2 = controller.panel

        XCTAssertTrue(panel1 === panel2,
            "Same mode should reuse the panel, not rebuild")
    }

    // MARK: - Compact is strictly smaller than full

    func test_compactIsSmallerThanFull() {
        appState.recordingState = .recording
        controller.updateFor(state: .recording)
        let compactSize = controller.panel!.frame.size

        appState.transcribedText = "Test transcription"
        appState.recordingState = .editing
        controller.updateFor(state: .editing)
        let fullSize = controller.panel!.frame.size

        XCTAssertLessThan(compactSize.width, fullSize.width,
            "Compact (\(compactSize.width)) should be narrower than full (\(fullSize.width))")
    }
}
