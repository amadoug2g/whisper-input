import AppKit
import CoreGraphics

/// Injects text directly as keystrokes using CGEvent unicode string injection.
/// This does NOT touch the system clipboard.
///
/// - Requires: Accessibility permission
///   (System Settings › Privacy & Security › Accessibility).
///
/// - Note: CGEvent unicode injection works in virtually all Cocoa apps.
///   A small handful of apps (Electron-based, some games) may ignore synthetic
///   events; for those, falling back to clipboard + Cmd+V is the safest option.
class PasteService {

    /// Injects `text` into whatever window has keyboard focus at call time.
    /// Must be called after the target app has been re-activated and focus
    /// has settled (the caller is responsible for that delay).
    func typeText(_ text: String) {
        guard !text.isEmpty else { return }
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        for scalar in text.unicodeScalars {
            if scalar == "\n" || scalar == "\r" {
                // Inject a hardware Return keystroke (keyCode 36) so apps that
                // handle \n structurally (e.g. multiline text views) get the
                // correct event.
                postKey(keyCode: 36, source: source)
            } else {
                // Build a UTF-16 representation of the character and attach it
                // to a synthetic key event with virtual keyCode 0.  The
                // receiving app reads the unicode payload, not the keyCode.
                var utf16 = Array(String(scalar).utf16)
                guard !utf16.isEmpty else { continue }

                let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
                down?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
                down?.post(tap: .cghidEventTap)

                let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
                up?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
                up?.post(tap: .cghidEventTap)
            }
        }
    }

    // MARK: - Private

    private func postKey(keyCode: CGKeyCode, source: CGEventSource) {
        CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)?
            .post(tap: .cghidEventTap)
        CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)?
            .post(tap: .cghidEventTap)
    }
}
