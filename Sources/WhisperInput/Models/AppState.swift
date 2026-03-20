import Foundation
import Combine

// MARK: - State types

enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case editing

    var menuBarIconName: String {
        switch self {
        case .idle:         return "mic.circle"
        case .recording:    return "mic.circle.fill"
        case .transcribing: return "waveform.circle"
        case .editing:      return "checkmark.circle"
        }
    }
}

enum RecordingMode: String, CaseIterable {
    case pushToTalk = "pushToTalk"
    case toggle     = "toggle"

    var label: String {
        switch self {
        case .pushToTalk: return "Hold to Record"
        case .toggle:     return "Tap to Toggle"
        }
    }

    var hint: String {
        switch self {
        case .pushToTalk: return "Hold ⌥ Space while speaking. Release to transcribe."
        case .toggle:     return "Tap ⌥ Space to start. Tap again to stop and transcribe."
        }
    }
}

// MARK: - AppState

@MainActor
class AppState: ObservableObject {
    // Recording / transcription
    @Published var recordingState: RecordingState = .idle
    @Published var transcribedText: String = ""
    @Published var errorMessage: String? = nil
    @Published var audioLevel: Float = 0.0   // [0, 1], updated while recording

    // Preferences
    @Published var recordingMode: RecordingMode = .pushToTalk
    @Published var autoPasteEnabled: Bool = false
    @Published var selectedLanguage: String = "auto"
    @Published var openAIApiKey: String = ""
    @Published var hotkeyKeyCode: Int = 49      // Space
    @Published var hotkeyModifiers: Int = 2048  // Carbon optionKey

    // Convenience
    var isRecording: Bool    { recordingState == .recording }
    var isTranscribing: Bool { recordingState == .transcribing }
    var isEditing: Bool      { recordingState == .editing }

    /// Injected by AppDelegate: hides the panel, re-activates the previous app,
    /// then calls PasteService.typeText(_:).
    var pasteHandler: ((String) -> Void)?

    // Private services
    private let audioRecorder = AudioRecorder()
    private let whisperService = WhisperService()

    init() {
        loadPreferences()

        // Forward audio level updates onto the main thread @Published property.
        audioRecorder.onLevelUpdate = { [weak self] level in
            Task { @MainActor [weak self] in
                self?.audioLevel = level
            }
        }
    }

    // MARK: - Permissions

    nonisolated func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AudioRecorder.requestPermission(completion: completion)
    }

    // MARK: - Recording lifecycle

    func startRecording() {
        guard recordingState == .idle else { return }
        errorMessage = nil

        AudioRecorder.requestPermission { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.recordingState == .idle else { return }

                guard granted else {
                    self.errorMessage = "Microphone access denied. Enable it in System Settings › Privacy & Security › Microphone."
                    return
                }

                do {
                    try self.audioRecorder.startRecording()
                    self.recordingState = .recording
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stopRecording() {
        guard recordingState == .recording else { return }
        recordingState = .transcribing
        audioLevel = 0

        audioRecorder.stopRecording { [weak self] url in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard let url else {
                    self.recordingState = .idle
                    return
                }
                await self.transcribe(audioURL: url)
            }
        }
    }

    // MARK: - Transcription

    private func transcribe(audioURL: URL) async {
        defer {
            // Always clean up the temp audio file
            try? FileManager.default.removeItem(at: audioURL)
        }

        do {
            let text = try await whisperService.transcribe(
                audioURL: audioURL,
                apiKey: openAIApiKey,
                language: selectedLanguage == "auto" ? nil : selectedLanguage
            )
            transcribedText = text
            if autoPasteEnabled {
                confirmAndPaste()
            } else {
                recordingState = .editing
            }
        } catch {
            errorMessage = error.localizedDescription
            recordingState = .idle
        }
    }

    // MARK: - Paste

    func confirmAndPaste() {
        let text = transcribedText
        reset()
        pasteHandler?(text)
    }

    // MARK: - Reset

    func reset() {
        transcribedText = ""
        errorMessage = nil
        recordingState = .idle
        audioLevel = 0
    }

    // MARK: - Preferences

    private func loadPreferences() {
        openAIApiKey     = KeychainService.load(forKey: "openAIApiKey") ?? ""
        selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "auto"
        if let raw = UserDefaults.standard.string(forKey: "recordingMode"),
           let mode = RecordingMode(rawValue: raw) {
            recordingMode = mode
        }
        autoPasteEnabled = UserDefaults.standard.bool(forKey: "autoPasteEnabled")
        let kc = UserDefaults.standard.integer(forKey: "hotkeyKeyCode")
        if kc > 0 { hotkeyKeyCode = kc }
        let km = UserDefaults.standard.integer(forKey: "hotkeyModifiers")
        if km > 0 { hotkeyModifiers = km }
    }

    func savePreferences() {
        if openAIApiKey.isEmpty {
            KeychainService.delete(forKey: "openAIApiKey")
        } else {
            KeychainService.save(openAIApiKey, forKey: "openAIApiKey")
        }
        UserDefaults.standard.set(selectedLanguage,       forKey: "selectedLanguage")
        UserDefaults.standard.set(recordingMode.rawValue, forKey: "recordingMode")
        UserDefaults.standard.set(autoPasteEnabled,       forKey: "autoPasteEnabled")
        UserDefaults.standard.set(hotkeyKeyCode,          forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(hotkeyModifiers,        forKey: "hotkeyModifiers")
    }
}
