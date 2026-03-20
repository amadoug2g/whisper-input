import SwiftUI
import Combine

/// Lightweight observable that the menu bar label and menu content observe.
/// It only publishes when `recordingState` or `recordingMode` change — not on
/// every `audioLevel` tick — so the menu bar icon won't re-render at 20 fps
/// during recording.
@MainActor
final class MenuBarState: ObservableObject {
    @Published private(set) var recordingState: RecordingState = .idle
    @Published private(set) var recordingMode: RecordingMode = .pushToTalk

    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        appState.$recordingState
            .receive(on: DispatchQueue.main)
            .assign(to: &$recordingState)
        appState.$recordingMode
            .receive(on: DispatchQueue.main)
            .assign(to: &$recordingMode)
    }
}

public struct WhisperInputApp: App {
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
        Image(systemName: menuBarState.recordingState.menuBarIconName)
            .accessibilityLabel("WhisperInput")
    }
}

private struct AppMenuView: View {
    let toggleRecording: () -> Void
    @ObservedObject var menuBarState: MenuBarState

    var body: some View {
        Text("Mode: \(menuBarState.recordingMode.label)")
            .disabled(true)
        Divider()
        Button(menuBarState.recordingState == .recording ? "Stop Recording" : "Start Recording  (⌥ Space)") {
            toggleRecording()
        }
        Divider()
        if #available(macOS 14, *) {
            SettingsLink()
        } else {
            Button("Settings…") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
        Divider()
        Button("Quit") {
            NSApp.terminate(nil)
        }
    }
}
