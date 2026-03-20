import SwiftUI

private enum KeyTestState: Equatable {
    case idle, testing, valid, invalid(String)
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    @State private var apiKey: String = ""
    @State private var language: String = "auto"
    @State private var mode: RecordingMode = .pushToTalk
    @State private var saved = false
    @State private var saveFailed = false
    @State private var keyTestState: KeyTestState = .idle

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
                    .accessibilityLabel("OpenAI API Key")
                    .onChange(of: apiKey) { _ in keyTestState = .idle }

                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text("Stored securely in the system Keychain.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    keyTestResultBadge
                    Button("Test Key") { testAPIKey() }
                        .buttonStyle(.borderless)
                        .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty
                                  || keyTestState == .testing)
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
                Text("Hotkey customization coming in a future release.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Hotkey")
            }

            // MARK: Save
            HStack {
                Spacer()
                if saveFailed {
                    Label("Keychain error — key not saved", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: 13, weight: .medium))
                        .transition(.opacity)
                } else if saved {
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
        .frame(minWidth: 440, maxWidth: 440, minHeight: 360)
        .padding()
        .onAppear(perform: loadFromAppState)
    }

    // MARK: - Key test result badge

    @ViewBuilder
    private var keyTestResultBadge: some View {
        switch keyTestState {
        case .idle:
            EmptyView()
        case .testing:
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 20, height: 20)
        case .valid:
            Label("Valid", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
                .transition(.opacity)
        case .invalid(let msg):
            Label(msg, systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.caption)
                .lineLimit(1)
                .transition(.opacity)
        }
    }

    // MARK: - Helpers

    private func keyBadge(_ label: String) -> some View {
        Text(label)
            .font(.callout.weight(.medium).monospaced())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
    }

    private func loadFromAppState() {
        apiKey   = appState.openAIApiKey
        language = appState.selectedLanguage
        mode     = appState.recordingMode
    }

    private func save() {
        appState.openAIApiKey     = apiKey
        appState.selectedLanguage = language
        appState.recordingMode    = mode
        let ok = appState.savePreferences()

        if ok {
            withAnimation { saved = true; saveFailed = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { saved = false }
            }
        } else {
            withAnimation { saveFailed = true; saved = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { saveFailed = false }
            }
        }
    }

    // MARK: - API Key test

    private func testAPIKey() {
        keyTestState = .testing
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
        Task {
            do {
                // Ephemeral session — the API key in the Authorization header
                // should not be persisted to any on-disk cache.
                let session = URLSession(configuration: .ephemeral)
                var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
                request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
                request.timeoutInterval = 10
                let (_, response) = try await session.data(for: request)
                if let http = response as? HTTPURLResponse {
                    withAnimation {
                        keyTestState = http.statusCode == 200
                            ? .valid
                            : .invalid("Invalid key — check your OpenAI account")
                    }
                }
            } catch {
                withAnimation {
                    keyTestState = .invalid("Couldn't reach OpenAI — check your connection")
                }
            }
            // Auto-clear after showing result
            try? await Task.sleep(for: .seconds(4))
            withAnimation { keyTestState = .idle }
        }
    }
}
