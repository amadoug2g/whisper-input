import AppKit
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    let appState = AppState()
    private var statusItem: NSStatusItem?
    private var floatingPanel: NSPanel?
    private var hotkeyManager: HotkeyManager?
    private let pasteService = PasteService()

    /// The app that was frontmost when the hotkey was pressed.
    /// We restore focus to it after pasting.
    private var previousApp: NSRunningApplication?

    private var stateCancellable: AnyCancellable?

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // menubar-only, no Dock icon

        setupMenuBar()
        setupHotkey()
        setupPasteHandler()
        observeRecordingState()
    }

    // MARK: - Menubar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "mic.circle", accessibilityDescription: "WhisperInput")
        button.target = self
        button.action = #selector(statusBarButtonClicked)
    }

    @objc private func statusBarButtonClicked() {
        let menu = NSMenu()

        let modeItem = NSMenuItem(
            title: "Mode: \(appState.recordingMode.label)",
            action: nil,
            keyEquivalent: ""
        )
        modeItem.isEnabled = false
        menu.addItem(modeItem)
        menu.addItem(.separator())

        let recordTitle = appState.isRecording ? "Stop Recording" : "Start Recording  (⌥ Space)"
        menu.addItem(NSMenuItem(title: recordTitle, action: #selector(menuToggleRecording), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
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

        hotkeyManager?.register() // default: ⌥ Space
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

    // MARK: - State observation → panel lifecycle + menubar icon

    private func observeRecordingState() {
        stateCancellable = appState.$recordingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateMenuBarIcon(for: state)
                self?.updatePanel(for: state)
            }
    }

    private func updateMenuBarIcon(for state: RecordingState) {
        let name: String
        switch state {
        case .idle:         name = "mic.circle"
        case .recording:    name = "mic.circle.fill"
        case .transcribing: name = "waveform.circle"
        case .editing:      name = "checkmark.circle"
        }
        statusItem?.button?.image = NSImage(
            systemSymbolName: name,
            accessibilityDescription: "WhisperInput"
        )
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
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 120),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
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

    @objc private func menuToggleRecording() {
        if appState.isRecording {
            appState.stopRecording()
        } else if appState.recordingState == .idle {
            capturePreviousApp()
            appState.startRecording()
        }
    }

    @objc private func openSettings() {
        // SettingsLink (the SwiftUI-preferred API) is macOS 14+ and only usable
        // inside a SwiftUI view hierarchy. From an AppKit @objc action such as
        // this one, sendAction with showSettingsWindow: is the correct approach.
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        if #available(macOS 14, *) { NSApp.activate() }
        else { NSApp.activate(ignoringOtherApps: true) }
    }
}
