import AppKit
import SwiftUI

/// Owns the floating HUD panel lifecycle: build, show, hide, position,
/// and click-outside dismissal. Extracted from AppDelegate to give it
/// a single responsibility.
@MainActor
final class PanelController {

    private var panel: FloatingPanel?
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
            show(activate: false, compact: true)
        case .editing:
            show(activate: true, compact: false)
            installClickOutsideMonitor()
        case .error:
            removeClickOutsideMonitor()
            show(activate: false, compact: false)
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

    private func show(activate: Bool, compact: Bool) {
        if panel == nil { panel = buildPanel() }

        if activate {
            if #available(macOS 14, *) { NSApp.activate() }
            else { NSApp.activate(ignoringOtherApps: true) }
            panel?.makeKeyAndOrderFront(nil)
        } else {
            panel?.orderFront(nil)
        }

        positionPanel(compact: compact)
    }

    private func buildPanel() -> FloatingPanel {
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
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(
            rootView: TranscriptionView()
                .environmentObject(appState)
        )
        return panel
    }

    private func positionPanel(compact: Bool) {
        guard let panel = panel, let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        // Compact pill: small, centered near the bottom of the screen.
        // Full panel: wider, slightly higher so the editor is comfortable.
        let contentSize = panel.contentView?.fittingSize ?? NSSize(width: 100, height: 40)
        let w = compact ? max(contentSize.width, 80) : 400
        let h = compact ? max(contentSize.height, 36) : panel.frame.height
        panel.setContentSize(NSSize(width: w, height: h))
        let x = sf.midX - panel.frame.width / 2
        let y = sf.minY + (compact ? 36 : 48)
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

// MARK: - FloatingPanel

/// NSPanel subclass that handles ⌘↩ and Escape directly at the window level,
/// bypassing NSTextView's responder chain so the shortcuts always fire.
final class FloatingPanel: NSPanel {
    weak var appState: AppState?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown,
              event.keyCode == 36,
              event.modifierFlags.contains(.command) else {
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

    override func cancelOperation(_ sender: Any?) {
        MainActor.assumeIsolated { appState?.reset() }
    }
}
