import AppKit
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    let appState = AppState()
    lazy var menuBarState = MenuBarState(appState: appState)
    private lazy var panelController = PanelController(appState: appState)
    private var hotkeyManager: HotkeyManager?
    private let pasteService = PasteService()
    private var previousApp: NSRunningApplication?
    private var stateCancellable: AnyCancellable?

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        appState.pasteOrchestrator = self
        setupHotkey()
        observeRecordingState()
    }

    // MARK: - Hotkey wiring

    private func setupHotkey() {
        hotkeyManager = HotkeyManager()
        hotkeyManager?.onKeyDown = { [weak self] in self?.handleHotkeyDown() }
        hotkeyManager?.onKeyUp   = { [weak self] in self?.handleHotkeyUp() }

        if !(hotkeyManager?.register() ?? false) {
            appState.hotkeyConflict = true
        }
    }

    private func handleHotkeyDown() {
        switch appState.recordingMode {
        case .pushToTalk:
            if appState.recordingState == .idle {
                capturePreviousApp()
                appState.startRecording()
            }
        case .toggle:
            if appState.recordingState == .idle {
                capturePreviousApp()
                appState.startRecording()
            } else if appState.recordingState == .recording {
                appState.stopRecording()
            }
        }
    }

    private func handleHotkeyUp() {
        guard appState.recordingMode == .pushToTalk,
              appState.recordingState == .recording else { return }
        appState.stopRecording()
    }

    // MARK: - State observation → panel lifecycle

    private func observeRecordingState() {
        stateCancellable = appState.$recordingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.panelController.updateFor(state: state)
            }
    }

    // MARK: - Helpers

    private func capturePreviousApp() {
        previousApp = NSWorkspace.shared.frontmostApplication
    }

    func menuToggleRecording() {
        if appState.isRecording {
            appState.stopRecording()
        } else if appState.recordingState == .idle {
            capturePreviousApp()
            appState.startRecording()
        }
    }
}

// MARK: - PasteOrchestrating

extension AppDelegate: PasteOrchestrating {
    func orchestratePaste(_ text: String) {
        panelController.hide()

        // Check Accessibility permission contextually — only when actually needed.
        guard AXIsProcessTrusted() else {
            showAccessibilityPermissionAlert()
            return
        }

        if let app = previousApp, !app.isTerminated {
            app.activate(options: .activateIgnoringOtherApps)
        }
        previousApp = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.pasteService.typeText(text)
        }
    }

    private func showAccessibilityPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility access required"
        alert.informativeText = "WhisperInput needs Accessibility access to paste transcribed text into other apps. Click \"Open Settings\" to grant access, then relaunch WhisperInput."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
