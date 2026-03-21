import AppKit
import CoreGraphics

/// Pastes text into the frontmost application using the system clipboard
/// and a simulated ⌘V keystroke.
///
/// This approach is more reliable than character-by-character CGEvent injection
/// because it works in Electron apps, terminal emulators, and apps that intercept
/// synthetic key events. The previous clipboard contents are saved and restored.
///
/// Requires: Accessibility permission (for CGEvent posting).
class PasteService {

    func typeText(_ text: String) {
        guard !text.isEmpty else { return }

        let pasteboard = NSPasteboard.general

        // Save current clipboard contents
        let savedChangeCount = pasteboard.changeCount
        let savedItems = pasteboard.pasteboardItems?.compactMap { item -> [NSPasteboard.PasteboardType: Data] in
            var dict = [NSPasteboard.PasteboardType: Data]()
            for type in item.types {
                if let data = item.data(forType: type) {
                    dict[type] = data
                }
            }
            return dict
        } ?? []

        // Set our text
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate ⌘V
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }
        let vKeyCode: CGKeyCode = 9  // 'v'

        let down = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        down?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)

        let up = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        up?.flags = .maskCommand
        up?.post(tap: .cghidEventTap)

        // Restore the previous clipboard after a short delay
        // (the target app needs time to read the paste).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Only restore if nobody else has changed the clipboard
            guard pasteboard.changeCount == savedChangeCount + 1 else { return }
            pasteboard.clearContents()
            for itemDict in savedItems {
                let item = NSPasteboardItem()
                for (type, data) in itemDict {
                    item.setData(data, forType: type)
                }
                pasteboard.writeObjects([item])
            }
        }
    }
}
