import SwiftUI
import AppKit
import CoreGraphics

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    // Local copies so the user can cancel unsaved changes
    @State private var apiKey: String = ""
    @State private var language: String = "auto"
    @State private var mode: RecordingMode = .pushToTalk
    @State private var autoPaste: Bool = false
    @State private var hotkeyKeyCode: Int = 49
    @State private var hotkeyModifiers: Int = 2048
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
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    Text("Stored securely in the system Keychain.")
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

            // MARK: Behavior
            Section {
                Toggle("Auto-paste (skip review)", isOn: $autoPaste)
                Text("Transcription is pasted immediately without showing the review panel.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Behavior")
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

            // MARK: Hotkey
            Section {
                HotkeyRecorderView(keyCode: $hotkeyKeyCode, modifiers: $hotkeyModifiers)
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
        apiKey          = appState.openAIApiKey
        language        = appState.selectedLanguage
        mode            = appState.recordingMode
        autoPaste       = appState.autoPasteEnabled
        hotkeyKeyCode   = appState.hotkeyKeyCode
        hotkeyModifiers = appState.hotkeyModifiers
    }

    private func save() {
        appState.openAIApiKey     = apiKey
        appState.selectedLanguage = language
        appState.recordingMode    = mode
        appState.autoPasteEnabled = autoPaste
        appState.hotkeyKeyCode    = hotkeyKeyCode
        appState.hotkeyModifiers  = hotkeyModifiers
        appState.savePreferences()

        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { saved = false }
        }
    }
}

// MARK: - HotkeyRecorderView

private struct HotkeyRecorderView: View {
    @Binding var keyCode: Int
    @Binding var modifiers: Int
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack {
            Text("Global shortcut")
            Spacer()
            if isRecording {
                Text("Press keys…")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                Button("Cancel") { stopRecording() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            } else {
                Text(displayString(keyCode: keyCode, modifiers: modifiers))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                Button("Change") { startRecording() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.modifierFlags.intersection([.command, .option, .control, .shift]) != [],
                  !isModifierOnlyKey(event.keyCode) else { return event }
            keyCode   = Int(event.keyCode)
            modifiers = carbonModifiers(from: event.modifierFlags)
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
        isRecording = false
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
        var c = 0
        if flags.contains(.option)  { c |= 2048 }
        if flags.contains(.command) { c |= 256  }
        if flags.contains(.control) { c |= 4096 }
        if flags.contains(.shift)   { c |= 512  }
        return c
    }

    private func isModifierOnlyKey(_ code: UInt16) -> Bool {
        [54, 55, 56, 57, 58, 59, 60, 61, 62, 63].contains(code)
    }

    private func displayString(keyCode: Int, modifiers: Int) -> String {
        var s = ""
        if modifiers & 4096 != 0 { s += "⌃" }
        if modifiers & 2048 != 0 { s += "⌥" }
        if modifiers & 512  != 0 { s += "⇧" }
        if modifiers & 256  != 0 { s += "⌘" }
        s += keyName(for: keyCode)
        return s
    }

    private func keyName(for code: Int) -> String {
        switch code {
        case 49: return "Space"
        case 36: return "↩"
        case 48: return "⇥"
        case 51: return "⌫"
        case 53: return "⎋"
        default:
            let src = CGEventSource(stateID: .hidSystemState)
            let evt = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(code), keyDown: true)
            var len = 0
            var chars = [UniChar](repeating: 0, count: 4)
            evt?.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &len, unicodeString: &chars)
            return (NSString(characters: chars, length: len) as String).uppercased()
        }
    }
}
