import SwiftUI

@main
struct WhisperInputApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No main window — this is a menubar-only app.
        // The floating transcription panel is managed by AppDelegate.
        Settings {
            SettingsView()
                .environmentObject(appDelegate.appState)
        }
    }
}
