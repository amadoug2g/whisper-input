import AppKit
import SwiftUI

/// Owns the floating HUD panel lifecycle: build, show, hide, position,
/// and click-outside dismissal. Extracted from AppDelegate to give it
/// a single responsibility.
@MainActor
final class PanelController {

    private(set) var panel: FloatingPanel?
    private var clickOutsideMonitor: Any?
    private(set) var isCompact: Bool?       // tracks current mode
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
        isCompact = nil
    }

    private func show(activate: Bool, compact: Bool) {
        // If the mode changed (compact ↔ full), destroy and rebuild so the
        // NSHostingView recalculates its intrinsic size from scratch.
        if isCompact != compact {
            panel?.orderOut(nil)
            panel = nil
        }
        isCompact = compact

        if panel == nil { panel = buildPanel(compact: compact) }

        if activate {
            if #available(macOS 14, *) { NSApp.activate() }
            else { NSApp.activate(ignoringOtherApps: true) }
            panel?.makeKeyAndOrderFront(nil)
        } else {
            panel?.orderFront(nil)
        }

        positionPanel()
    }

    private func buildPanel(compact: Bool) -> FloatingPanel {
        let rootView = TranscriptionView()
            .environmentObject(appState)

        let hostingView = NSHostingView(rootView: rootView)
        // Let the hosting view calculate its ideal size from the SwiftUI content.
        let fittingSize = hostingView.fittingSize

        let panel = FloatingPanel(
            contentRect: NSRect(origin: .zero, size: fittingSize),
            styleMask: [.borderless, .nonactivatingPanel],
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
        panel.contentView = hostingView
        return panel
    }

    private func positionPanel() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        let x = sf.midX - panel.frame.width / 2
        let y = sf.minY + ((isCompact == true) ? 40 : 48)
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
