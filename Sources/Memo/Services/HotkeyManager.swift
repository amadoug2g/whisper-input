import AppKit
import Carbon

// MARK: - C-compatible event handler (must be a free function, not a closure)

private func carbonHotkeyHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData, let event else { return OSStatus(eventNotHandledErr) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    let kind = GetEventKind(event)
    if kind == UInt32(kEventHotKeyPressed) {
        DispatchQueue.main.async { manager.handleKeyDown() }
    } else if kind == UInt32(kEventHotKeyReleased) {
        DispatchQueue.main.async { manager.handleKeyUp() }
    }
    return noErr
}

// MARK: -

/// Registers a global hotkey via the Carbon Event Manager.
class HotkeyManager {
    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private var hotkeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    private(set) var keyDownAt: Date?

    var wasTap: Bool {
        guard let t = keyDownAt else { return false }
        return Date().timeIntervalSince(t) < 0.3
    }

    // MARK: - Registration

    /// Registers the global hotkey. Returns `true` if registration succeeded.
    @discardableResult
    func register(keyCode: UInt32 = 49, modifiers: UInt32 = UInt32(optionKey)) -> Bool {
        // Clean up any existing registration before re-registering
        if let ref = hotkeyRef { UnregisterEventHotKey(ref); hotkeyRef = nil }
        if let ref = handlerRef { RemoveEventHandler(ref); handlerRef = nil }

        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased)),
        ]

        InstallEventHandler(
            GetApplicationEventTarget(),
            carbonHotkeyHandler,
            eventTypes.count,
            &eventTypes,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )

        let hotKeyID = EventHotKeyID(signature: fourCharCode("MEMO"), id: 1)
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotkeyRef)
        return status == noErr
    }

    // MARK: - Internal handlers

    func handleKeyDown() {
        keyDownAt = Date()
        onKeyDown?()
    }

    func handleKeyUp() {
        defer { keyDownAt = nil }
        onKeyUp?()
    }

    // MARK: - Lifecycle

    deinit {
        if let ref = hotkeyRef { UnregisterEventHotKey(ref) }
        if let ref = handlerRef { RemoveEventHandler(ref) }
    }
}

// MARK: - Helper

private func fourCharCode(_ s: String) -> OSType {
    var result: OSType = 0
    for byte in s.utf8.prefix(4) {
        result = (result << 8) | OSType(byte)
    }
    return result
}
