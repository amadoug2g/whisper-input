import Foundation
import Combine

enum RecordingState {
    case idle
    case recording
    case transcribing
    case editing
}

class AppState: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var transcribedText: String = ""
    @Published var errorMessage: String? = nil

    // User preferences (persisted via UserDefaults)
    @Published var selectedLanguage: String = "auto"
    @Published var openAIApiKey: String = ""

    var isRecording: Bool { recordingState == .recording }
    var isTranscribing: Bool { recordingState == .transcribing }

    private let audioRecorder = AudioRecorder()
    private let whisperService = WhisperService()
    private let pasteService = PasteService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadPreferences()
    }

    // MARK: - Recording lifecycle

    func startRecording() {
        guard recordingState == .idle else { return }
        do {
            try audioRecorder.startRecording()
            recordingState = .recording
        } catch {
            errorMessage = "Microphone error: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        guard recordingState == .recording else { return }
        recordingState = .transcribing
        audioRecorder.stopRecording { [weak self] audioURL in
            guard let self, let url = audioURL else {
                self?.recordingState = .idle
                return
            }
            Task {
                await self.transcribe(audioURL: url)
            }
        }
    }

    // MARK: - Transcription

    @MainActor
    private func transcribe(audioURL: URL) async {
        do {
            let text = try await whisperService.transcribe(
                audioURL: audioURL,
                apiKey: openAIApiKey,
                language: selectedLanguage == "auto" ? nil : selectedLanguage
            )
            transcribedText = text
            recordingState = .editing
        } catch {
            errorMessage = "Transcription failed: \(error.localizedDescription)"
            recordingState = .idle
        }
    }

    // MARK: - Paste

    func confirmAndPaste() {
        pasteService.paste(text: transcribedText)
        reset()
    }

    func reset() {
        transcribedText = ""
        errorMessage = nil
        recordingState = .idle
    }

    // MARK: - Preferences

    private func loadPreferences() {
        openAIApiKey = UserDefaults.standard.string(forKey: "openAIApiKey") ?? ""
        selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "auto"
    }

    func savePreferences() {
        UserDefaults.standard.set(openAIApiKey, forKey: "openAIApiKey")
        UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
    }
}
