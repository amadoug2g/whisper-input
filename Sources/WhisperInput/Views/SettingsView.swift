import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var apiKeyInput: String = ""

    // Whisper-supported languages (partial list — extend as needed)
    let languages: [(label: String, code: String)] = [
        ("Auto-detect", "auto"),
        ("English", "en"),
        ("Spanish", "es"),
        ("French", "fr"),
        ("German", "de"),
        ("Italian", "it"),
        ("Portuguese", "pt"),
        ("Dutch", "nl"),
        ("Japanese", "ja"),
        ("Korean", "ko"),
        ("Chinese", "zh"),
        ("Arabic", "ar"),
        ("Russian", "ru"),
        ("Hindi", "hi"),
    ]

    var body: some View {
        Form {
            Section("API") {
                SecureField("OpenAI API Key", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                Text("Your key is stored in UserDefaults. For production, use Keychain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Language") {
                Picker("Input language", selection: $appState.selectedLanguage) {
                    ForEach(languages, id: \.code) { lang in
                        Text(lang.label).tag(lang.code)
                    }
                }
                .pickerStyle(.menu)
                Text("Setting a specific language improves accuracy and speed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Hotkey") {
                // TODO: Implement hotkey recorder UI
                HStack {
                    Text("Global shortcut")
                    Spacer()
                    Text("⌥ Space")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Text("Hotkey customization coming soon.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Save") { saveSettings() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
        .onAppear { apiKeyInput = appState.openAIApiKey }
    }

    private func saveSettings() {
        appState.openAIApiKey = apiKeyInput
        appState.savePreferences()
    }
}
