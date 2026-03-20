import AppKit
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    let appState = AppState()
    /// Initialized lazily so appState is guaranteed to exist first.
    lazy var menuBarState = MenuBarState(appState: appState)
    private var floatingPanel: NSPanel?
    private var hotkeyManager: HotkeyManager?
    private let pasteService = PasteService()

    /// The app that was frontmost when the hotkey was pressed.
    /// We restore focus to it after pasting.
    private var previousApp: NSRunningApplication?

    private var stateCancellable: AnyCancellable?
    private var hotkeySettingsCancellable: AnyCancellable?

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // menubar-only, no Dock icon

        requestAccessibilityIfNeeded()
        setupHotkey()
        setupPasteHandler()
        observeRecordingState()
    }

    /// Prompts the user to grant Accessibility access if not already granted.
    /// CGEvent-based text injection (PasteService) requires this permission.
    private func requestAccessibilityIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    // MARK: - Hotkey wiring

    private func setupHotkey() {
        hotkeyManager = HotkeyManager()

        hotkeyManager?.onKeyDown = { [weak self] in
            self?.handleHotkeyDown()
        }
        hotkeyManager?.onKeyUp = { [weak self] in
            self?.handleHotkeyUp()
        }

        hotkeyManager?.register(keyCode: UInt32(appState.hotkeyKeyCode),
                                modifiers: UInt32(appState.hotkeyModifiers))

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
            // Start recording on key-down; release will stop it.
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
            // Ignore hotkey while transcribing/editing
        }
    }

    private func handleHotkeyUp() {
        // Only relevant in push-to-talk mode
        guard appState.recordingMode == .pushToTalk,
              appState.recordingState == .recording else { return }
        appState.stopRecording()
    }

    // MARK: - State observation → panel lifecycle

    private func observeRecordingState() {
        stateCancellable = appState.$recordingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updatePanel(for: state)
            }
    }

    private func updatePanel(for state: RecordingState) {
        switch state {
        case .recording, .transcribing:
            // Show HUD without stealing focus so the user can keep typing
            showPanel(activate: false)

        case .editing:
            // Now we need keyboard input — activate our app and make the panel key
            showPanel(activate: true)

        case .idle:
            hidePanel()
        }
    }

    // MARK: - Floating panel

    private func showPanel(activate: Bool) {
        if floatingPanel == nil {
            floatingPanel = buildPanel()
        }

        if activate {
            if #available(macOS 14, *) { NSApp.activate() }
            else { NSApp.activate(ignoringOtherApps: true) }
            floatingPanel?.makeKeyAndOrderFront(nil)
        } else {
            floatingPanel?.orderFront(nil)
        }

        positionPanelNearMouse()
    }

    private func hidePanel() {
        floatingPanel?.orderOut(nil)
        // Nil the panel so it is recreated fresh on the next session,
        // which ensures the SwiftUI state tree starts clean.
        floatingPanel = nil
    }

    private func buildPanel() -> NSPanel {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 120),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.appState = appState
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false  // shadow rendered by SwiftUI view itself
        panel.isMovableByWindowBackground = true
        panel.contentView = NSHostingView(
            rootView: TranscriptionView()
                .environmentObject(appState)
        )
        return panel
    }

    private func positionPanelNearMouse() {
        guard let panel = floatingPanel,
              let screen = NSScreen.main else { return }

        let mouse = NSEvent.mouseLocation
        let pw = panel.frame.width
        let ph: CGFloat = 150  // approximate; panel auto-sizes via SwiftUI

        var x = mouse.x - pw / 2
        var y = mouse.y - ph - 16  // just below cursor

        let sf = screen.visibleFrame
        x = max(sf.minX + 8, min(x, sf.maxX - pw - 8))
        y = max(sf.minY + 8, min(y, sf.maxY - ph - 8))

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Paste

    private func setupPasteHandler() {
        appState.pasteHandler = { [weak self] text in
            self?.performPaste(text)
        }
    }

    private func performPaste(_ text: String) {
        hidePanel()

        // Re-activate the app that had focus before we recorded
        if let app = previousApp, !app.isTerminated {
            app.activate(options: .activateIgnoringOtherApps)
        }
        previousApp = nil

        // Give the OS ~150 ms to settle focus before injecting keystrokes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.pasteService.typeText(text)
        }
    }

    // MARK: - Helpers

    private func capturePreviousApp() {
        previousApp = NSWorkspace.shared.frontmostApplication
    }

    /// Called by the SwiftUI menu bar to toggle recording.
    func menuToggleRecording() {
        if appState.isRecording {
            appState.stopRecording()
        } else if appState.recordingState == .idle {
            capturePreviousApp()
            appState.startRecording()
        }
    }
}

// MARK: - FloatingPanel

/// NSPanel subclass that handles ⌘↩ and Escape directly at the window level,
/// bypassing NSTextView's responder chain so the shortcuts always fire.
private final class FloatingPanel: NSPanel {
    weak var appState: AppState?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Called before the event is dispatched to any view — reliable for key equivalents.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown,
              event.keyCode == 36,                          // Return
              event.modifierFlags.contains(.command) else { // ⌘
            return super.performKeyEquivalent(with: event)
        }
        return MainActor.assumeIsolated {
            guard let state = appState,
                  state.isEditing,
                  !state.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return super.performKeyEquivalent(with: event) }
            state.confirmAndPaste()
            return true
        }
    }

    /// Standard AppKit hook for Escape — more reliable than a local event monitor.
    override func cancelOperation(_ sender: Any?) {
        MainActor.assumeIsolated { appState?.reset() }
    }
}
