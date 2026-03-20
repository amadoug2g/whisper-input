import AppKit

/// Pastes text into whatever field had focus before the floating panel appeared.
/// Strategy:
///   1. Write text to the pasteboard.
///   2. Simulate Cmd+V via CGEvent (requires Accessibility permission).
/// Alternative: use NSWorkspace to call `pbpaste` if CGEvent is blocked.
class PasteService {
    func paste(text: String) {
        // 1. Write to pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // 2. Simulate Cmd+V
        // The panel must resign key status first so the previously active app regains focus.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }

    private func simulatePaste() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        // Key down: Cmd+V (keyCode 9 = 'v')
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        // Key up
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
}
