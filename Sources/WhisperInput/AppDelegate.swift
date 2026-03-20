import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var floatingPanel: NSPanel?
    let appState = AppState()
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock — menubar-only app
        NSApp.setActivationPolicy(.accessory)

        setupMenuBar()
        setupHotkey()
    }

    // MARK: - Menubar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "mic.circle", accessibilityDescription: "WhisperInput")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }

    @objc private func statusBarButtonClicked() {
        showMenu()
    }

    private func showMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Start Recording  (⌥Space)", action: #selector(toggleRecording), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit WhisperInput", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    // MARK: - Hotkey

    private func setupHotkey() {
        hotkeyManager = HotkeyManager()
        // Default: Option + Space
        hotkeyManager?.register(modifiers: [.option], key: .space) { [weak self] in
            self?.toggleRecording()
        }
    }

    // MARK: - Recording

    @objc func toggleRecording() {
        if appState.isRecording {
            appState.stopRecording()
            showFloatingPanel()
        } else {
            appState.startRecording()
        }
    }

    // MARK: - Floating Panel

    func showFloatingPanel() {
        if floatingPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 200),
                styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.title = "WhisperInput"
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.center()
            panel.contentView = NSHostingView(
                rootView: TranscriptionView()
                    .environmentObject(appState)
            )
            floatingPanel = panel
        }
        floatingPanel?.makeKeyAndOrderFront(nil)
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
