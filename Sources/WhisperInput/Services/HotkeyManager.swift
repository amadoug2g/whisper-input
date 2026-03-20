import AppKit
import Carbon

/// Registers a global hotkey using the Carbon Event Manager.
/// The app must NOT be sandboxed to listen to global key events,
/// or must request the Accessibility permission (System Settings > Privacy > Accessibility).
class HotkeyManager {
    private var eventHotKeyRef: EventHotKeyRef?
    private var handler: (() -> Void)?

    // Carbon event handler (C-compatible)
    private var eventHandler: EventHandlerRef?

    struct Modifiers: OptionSet {
        let rawValue: UInt32
        static let command = Modifiers(rawValue: UInt32(cmdKey))
        static let option  = Modifiers(rawValue: UInt32(optionKey))
        static let control = Modifiers(rawValue: UInt32(controlKey))
        static let shift   = Modifiers(rawValue: UInt32(shiftKey))
    }

    enum Key: UInt32 {
        case space = 49
        // Add more keycodes as needed: https://eastmanreference.com/complete-list-of-applescript-key-codes
    }

    func register(modifiers: Modifiers, key: Key, action: @escaping () -> Void) {
        self.handler = action

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // Install Carbon event handler
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handler?()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        // Register the hotkey
        let hotKeyID = EventHotKeyID(signature: OSType(0x5749_4E50 /* WINP */), id: 1)
        RegisterEventHotKey(key.rawValue, modifiers.rawValue, hotKeyID, GetApplicationEventTarget(), 0, &eventHotKeyRef)
    }

    deinit {
        if let ref = eventHotKeyRef { UnregisterEventHotKey(ref) }
        if let handler = eventHandler { RemoveEventHandler(handler) }
    }
}
