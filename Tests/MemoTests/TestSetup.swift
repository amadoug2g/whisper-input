import XCTest
import AppKit

// Initializes NSApplication.shared once before any test runs.
// PanelController calls NSApp.activate() and panel.orderFront() — these
// require a shared NSApplication to exist even in a test context.
private final class AppKitTestObserver: NSObject, XCTestObservation {
    func testBundleWillStart(_ testBundle: Bundle) {
        _ = NSApplication.shared
    }
}

// Module-level init runs before any XCTestCase class is loaded.
private let _observer: AppKitTestObserver = {
    let obs = AppKitTestObserver()
    XCTestObservationCenter.shared.addTestObserver(obs)
    return obs
}()
