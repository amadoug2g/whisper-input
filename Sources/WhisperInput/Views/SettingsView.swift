import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    // Local copies so the user can cancel unsaved changes
    @State private var apiKey: String = ""
    @State private var language: String = "auto"
    @State private var mode: RecordingMode = .pushToTalk
    @State private var saved = false

    private let languages: [(label: String, code: String)] = [
        ("Auto-detect",  "auto"),
        ("English",      "en"),
        ("Spanish",      "es"),
        ("French",       "fr"),
        ("German",       "de"),
        ("Italian",      "it"),
        ("Portuguese",   "pt"),
        ("Dutch",        "nl"),
        ("Japanese",     "ja"),
        ("Korean",       "ko"),
        ("Chinese",      "zh"),
        ("Arabic",       "ar"),
        ("Russian",      "ru"),
        ("Hindi",        "hi"),
        ("Turkish",      "tr"),
        ("Polish",       "pl"),
        ("Swedish",      "sv"),
        ("Ukrainian",    "uk"),
    ]

    var body: some View {
        Form {

            // MARK: API Key
            Section {
                SecureField("sk-…", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Stored in UserDefaults. Move to Keychain for production use.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("OpenAI API Key")
            }

            // MARK: Recording Mode
            Section {
                Picker("Mode", selection: $mode) {
                    ForEach(RecordingMode.allCases, id: \.self) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.radioGroup)
                Text(mode.hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Input Mode")
            }

            // MARK: Language
            Section {
                Picker("Language", selection: $language) {
                    ForEach(languages, id: \.code) { lang in
                        Text(lang.label).tag(lang.code)
                    }
                }
                .pickerStyle(.menu)
                Text("Specifying a language improves accuracy and reduces latency.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Transcription Language")
            }

            // MARK: Hotkey (read-only for now)
            Section {
                HStack {
                    Text("Global shortcut")
                    Spacer()
                    keyBadge("⌥ Space")
                }
                Text("Hotkey customisation coming in a future release.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Hotkey")
            }

            // MARK: Save
            HStack {
                Spacer()
                if saved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 13, weight: .medium))
                        .transition(.opacity)
                }
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.top, 4)
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .padding()
        .onAppear(perform: loadFromAppState)
    }

    // MARK: - Helpers

    private func keyBadge(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
    }

    private func loadFromAppState() {
        apiKey   = appState.openAIApiKey
        language = appState.selectedLanguage
        mode     = appState.recordingMode
    }

    private func save() {
        appState.openAIApiKey    = apiKey
        appState.selectedLanguage = language
        appState.recordingMode   = mode
        appState.savePreferences()

        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { saved = false }
        }
    }
}
