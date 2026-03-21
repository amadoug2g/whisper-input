import Foundation

/// Encapsulates all user preference persistence: UserDefaults + Keychain.
/// Keeps `AppState` free of persistence concerns.
struct PreferencesStore {
    var apiKey: String
    var language: String
    var recordingMode: RecordingMode
    var autoPasteEnabled: Bool
    var hotkeyKeyCode: Int
    var hotkeyModifiers: Int

    init(
        apiKey: String = "",
        language: String = "auto",
        recordingMode: RecordingMode = .pushToTalk,
        autoPasteEnabled: Bool = false,
        hotkeyKeyCode: Int = 49,
        hotkeyModifiers: Int = 2048
    ) {
        self.apiKey = apiKey
        self.language = language
        self.recordingMode = recordingMode
        self.autoPasteEnabled = autoPasteEnabled
        self.hotkeyKeyCode = hotkeyKeyCode
        self.hotkeyModifiers = hotkeyModifiers
    }

    /// Full load — includes Keychain (10–50ms). Use only when launch latency is not a concern.
    static func load() -> PreferencesStore {
        var prefs = loadFast()
        prefs.apiKey = KeychainService.load(forKey: "openAIApiKey") ?? ""
        return prefs
    }

    /// Fast load — UserDefaults only (< 1ms). Use during app init to avoid blocking the launch path.
    static func loadFast() -> PreferencesStore {
        let language = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "auto"
        var recordingMode = RecordingMode.pushToTalk
        if let raw = UserDefaults.standard.string(forKey: "recordingMode"),
           let mode = RecordingMode(rawValue: raw) {
            recordingMode = mode
        }
        let autoPaste = UserDefaults.standard.bool(forKey: "autoPasteEnabled")
        let kc = UserDefaults.standard.integer(forKey: "hotkeyKeyCode")
        let km = UserDefaults.standard.integer(forKey: "hotkeyModifiers")
        return PreferencesStore(
            apiKey: "",
            language: language,
            recordingMode: recordingMode,
            autoPasteEnabled: autoPaste,
            hotkeyKeyCode: kc > 0 ? kc : 49,
            hotkeyModifiers: km > 0 ? km : 2048
        )
    }

    /// Persists all preferences. Returns `false` if the Keychain write fails.
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
        UserDefaults.standard.set(autoPasteEnabled,       forKey: "autoPasteEnabled")
        UserDefaults.standard.set(hotkeyKeyCode,          forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(hotkeyModifiers,        forKey: "hotkeyModifiers")
        return keychainOK
    }
}
