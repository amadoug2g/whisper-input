import Foundation

/// Encapsulates all user preference persistence: UserDefaults + Keychain.
/// Keeps `AppState` free of persistence concerns.
struct PreferencesStore {
    var apiKey: String
    var language: String
    var recordingMode: RecordingMode

    init(apiKey: String = "", language: String = "auto", recordingMode: RecordingMode = .pushToTalk) {
        self.apiKey = apiKey
        self.language = language
        self.recordingMode = recordingMode
    }

    /// Full load — includes Keychain (10–50ms). Use only when launch latency is not a concern.
    static func load() -> PreferencesStore {
        var prefs = loadFast()
        prefs.apiKey = KeychainService.load(forKey: "openAIApiKey") ?? ""
        return prefs
    }

    /// Fast load — UserDefaults only (< 1ms). Use during app init to avoid blocking the launch path.
    /// Load the API key separately via Keychain after the first frame.
    static func loadFast() -> PreferencesStore {
        let language = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "auto"
        var recordingMode = RecordingMode.pushToTalk
        if let raw = UserDefaults.standard.string(forKey: "recordingMode"),
           let mode = RecordingMode(rawValue: raw) {
            recordingMode = mode
        }
        return PreferencesStore(apiKey: "", language: language, recordingMode: recordingMode)
    }

    /// Persists all preferences. Returns `false` if the Keychain write fails —
    /// the caller should notify the user when this happens.
    @discardableResult
    func save() -> Bool {
        let keychainOK: Bool
        if apiKey.isEmpty {
            KeychainService.delete(forKey: "openAIApiKey")
            keychainOK = true
        } else {
            keychainOK = KeychainService.save(apiKey, forKey: "openAIApiKey")
        }
        UserDefaults.standard.set(language,              forKey: "selectedLanguage")
        UserDefaults.standard.set(recordingMode.rawValue, forKey: "recordingMode")
        return keychainOK
    }
}
