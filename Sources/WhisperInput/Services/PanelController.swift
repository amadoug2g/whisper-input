import AppKit
import SwiftUI

/// Owns the floating HUD panel lifecycle: build, show, hide, position,
/// and click-outside dismissal. Extracted from AppDelegate to give it
/// a single responsibility.
@MainActor
final class PanelController {

    private var panel: NSPanel?
    private var clickOutsideMonitor: Any?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - State-driven update

    func updateFor(state: RecordingState) {
        switch state {
        case .recording, .transcribing:
            removeClickOutsideMonitor()
            show(activate: false)
        case .editing:
            show(activate: true)
            installClickOutsideMonitor()
        case .error:
            removeClickOutsideMonitor()
            show(activate: false)
        case .idle:
            hide()
        }
    }

    // MARK: - Panel lifecycle

    func hide() {
        removeClickOutsideMonitor()
        panel?.orderOut(nil)
        panel = nil
    }

    private func show(activate: Bool) {
        if panel == nil { panel = buildPanel() }

        if activate {
            if #available(macOS 14, *) { NSApp.activate() }
            else { NSApp.activate(ignoringOtherApps: true) }
            panel?.makeKeyAndOrderFront(nil)
        } else {
            panel?.orderFront(nil)
        }

        positionPanel()
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
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        // Prevents the HUD from vanishing when focus returns to the dictation target.
        panel.hidesOnDeactivate = false
        // Appears over full-screen apps and on all Spaces.
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(
            rootView: TranscriptionView()
                .environmentObject(appState)
        )
        return panel
    }

    /// Positions the panel at a consistent bottom-center location.
    private func positionPanel() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        let x = sf.midX - panel.frame.width / 2
        let y = sf.minY + 48   // comfortably above the Dock
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Click-outside dismissal (editing state only)

    private func installClickOutsideMonitor() {
        guard clickOutsideMonitor == nil else { return }
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            guard let self, let panel = self.panel else { return }
            if !panel.frame.contains(NSEvent.mouseLocation) {
                self.appState.reset()
            }
        }
    }

    private func removeClickOutsideMonitor() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }
}
