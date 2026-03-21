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
    private var hotkeySettingsCancellable: AnyCancellable?

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

        if !(hotkeyManager?.register(keyCode: UInt32(appState.hotkeyKeyCode),
                                      modifiers: UInt32(appState.hotkeyModifiers)) ?? false) {
            appState.hotkeyConflict = true
        }

        hotkeySettingsCancellable = Publishers.CombineLatest(
            appState.$hotkeyKeyCode,
            appState.$hotkeyModifiers
        )
        .dropFirst()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] keyCode, modifiers in
            self?.hotkeyManager?.register(keyCode: UInt32(keyCode),
                                          modifiers: UInt32(modifiers))
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

        // Check Accessibility permission. On modern macOS (Ventura+), granting
        // permission takes effect immediately without relaunch.
        guard AXIsProcessTrusted() else {
            requestAccessibilityAndRetryPaste(text)
            return
        }

        performPaste(text)
    }

    private func performPaste(_ text: String) {
        if let app = previousApp, !app.isTerminated {
            app.activate(options: .activateIgnoringOtherApps)
        }
        previousApp = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.pasteService.typeText(text)
        }
    }

    /// Shows the system Accessibility prompt and polls until the user grants it.
    /// When granted, automatically completes the pending paste.
    private func requestAccessibilityAndRetryPaste(_ text: String) {
        // Trigger the system permission prompt (shows the toggle in System Settings).
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)

        // Poll every second for up to 30 seconds. Once the user flips the toggle
        // in System Settings, AXIsProcessTrusted() returns true immediately on
        // macOS 13+ — no relaunch needed.
        Task { @MainActor [weak self] in
            for _ in 0..<30 {
                try? await Task.sleep(for: .seconds(1))
                if AXIsProcessTrusted() {
                    self?.performPaste(text)
                    return
                }
            }
        }
    }
}
