import SwiftUI
import Combine

@MainActor
final class MenuBarState: ObservableObject {
    @Published private(set) var recordingState: RecordingState = .idle
    @Published private(set) var recordingMode: RecordingMode = .pushToTalk
    @Published private(set) var needsSetup: Bool = true
    @Published private(set) var hotkeyConflict: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        appState.$recordingState
            .receive(on: DispatchQueue.main)
            .assign(to: &$recordingState)
        appState.$recordingMode
            .receive(on: DispatchQueue.main)
            .assign(to: &$recordingMode)
        appState.$openAIApiKey
            .map { $0.trimmingCharacters(in: .whitespaces).isEmpty }
            .receive(on: DispatchQueue.main)
            .assign(to: &$needsSetup)
        appState.$hotkeyConflict
            .receive(on: DispatchQueue.main)
            .assign(to: &$hotkeyConflict)
    }
}

public struct MemoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    public init() {}

    public var body: some Scene {
        MenuBarExtra {
            AppMenuView(
                toggleRecording: { appDelegate.menuToggleRecording() },
                menuBarState: appDelegate.menuBarState
            )
        } label: {
            MenuBarLabelView(menuBarState: appDelegate.menuBarState)
        }

        Settings {
            SettingsView()
                .environmentObject(appDelegate.appState)
        }
    }
}

private struct MenuBarLabelView: View {
    @ObservedObject var menuBarState: MenuBarState

    var body: some View {
        let iconName = menuBarState.needsSetup
            ? "exclamationmark.circle"
            : menuBarState.recordingState.menuBarIconName
        Image(systemName: iconName)
            .accessibilityLabel("Memo — \(menuBarState.recordingState.accessibilityDescription)")
            .help("Memo — hold ⌥ Space to record")
    }
}

private extension RecordingState {
    var menuBarIconName: String {
        switch self {
        case .idle:         return "mic.circle"
        case .recording:    return "mic.circle.fill"
        case .transcribing: return "waveform.circle"
        case .editing:      return "checkmark.circle"
        case .error:        return "exclamationmark.circle"
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .idle:         return "Idle"
        case .recording:    return "Recording"
        case .transcribing: return "Transcribing"
        case .editing:      return "Review ready"
        case .error:        return "Error"
        }
    }
}

private struct AppMenuView: View {
    let toggleRecording: () -> Void
    @ObservedObject var menuBarState: MenuBarState

    private func openSettings() {
        if #available(macOS 14, *) { NSApp.activate() }
        else { NSApp.activate(ignoringOtherApps: true) }
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    var body: some View {
        if menuBarState.needsSetup {
            Text("Memo turns speech into text using OpenAI Whisper.")
                .foregroundStyle(.secondary)
            Text("Add an API key in Settings to get started.")
                .foregroundStyle(.secondary)
            Button("Open Settings…") { openSettings() }
            Divider()
        }

        if menuBarState.hotkeyConflict {
            Label("Hotkey ⌥Space is claimed by another app",
                  systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Divider()
        }

        Section(menuBarState.recordingMode.label) {}
        Divider()

        Button(menuBarState.recordingState == .recording ? "Stop Recording" : "Start Recording (⌥ Space)") {
            toggleRecording()
        }
        .disabled(menuBarState.needsSetup)
        Divider()
        Button("Settings…") { openSettings() }
        Divider()
        Button("Quit") {
            NSApp.terminate(nil)
        }
    }
}
