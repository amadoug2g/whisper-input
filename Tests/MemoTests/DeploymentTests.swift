import XCTest
import Foundation

/// Validates the app bundle structure and deployment assumptions.
/// These tests catch configuration issues that cause launch failures
/// (like unsigned binaries in /Applications).
final class DeploymentTests: XCTestCase {

    private let fm = FileManager.default
    private lazy var projectRoot: URL = {
        // Tests/MemoTests/DeploymentTests.swift → project root
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // MemoTests/
            .deletingLastPathComponent()  // Tests/
            .deletingLastPathComponent()  // project root
    }()

    private lazy var bundlePath: URL = projectRoot.appendingPathComponent("Memo.app")
    private lazy var binaryPath: URL = bundlePath
        .appendingPathComponent("Contents/MacOS/Memo")
    private lazy var plistPath: URL = bundlePath
        .appendingPathComponent("Contents/Info.plist")

    // MARK: - Bundle structure

    func test_appBundle_exists() throws {
        // Build creates Memo.app in the project root.
        // If this fails, `swift build` or the bundle assembly step is broken.
        try XCTSkipUnless(
            fm.fileExists(atPath: bundlePath.path),
            "Memo.app not built yet — run ./run.sh first"
        )
    }

    func test_appBundle_hasBinary() throws {
        try XCTSkipUnless(fm.fileExists(atPath: bundlePath.path), "Memo.app not built yet")

        XCTAssertTrue(
            fm.isExecutableFile(atPath: binaryPath.path),
            "Memo.app/Contents/MacOS/Memo must exist and be executable"
        )
    }

    func test_appBundle_hasInfoPlist() throws {
        try XCTSkipUnless(fm.fileExists(atPath: bundlePath.path), "Memo.app not built yet")

        XCTAssertTrue(
            fm.fileExists(atPath: plistPath.path),
            "Memo.app/Contents/Info.plist must exist"
        )
    }

    func test_infoPlist_hasRequiredKeys() throws {
        try XCTSkipUnless(fm.fileExists(atPath: plistPath.path), "Info.plist not found")

        let data = try Data(contentsOf: plistPath)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        let dict = try XCTUnwrap(plist as? [String: Any])

        XCTAssertEqual(dict["CFBundleIdentifier"] as? String, "com.memo.app")
        XCTAssertEqual(dict["CFBundleName"] as? String, "Memo")
        XCTAssertEqual(dict["CFBundleExecutable"] as? String, "Memo")

        // LSUIElement = true means menu-bar-only (no Dock icon).
        // This MUST be true, otherwise the app behaves differently.
        XCTAssertEqual(dict["LSUIElement"] as? Bool, true,
            "LSUIElement must be true for a menu-bar-only app")

        XCTAssertNotNil(dict["NSMicrophoneUsageDescription"],
            "Microphone usage description is required for recording")
    }

    // MARK: - Code signing vs launch location

    func test_unsignedBinary_mustNotLaunchFromApplications() throws {
        try XCTSkipUnless(fm.fileExists(atPath: binaryPath.path), "Binary not built yet")

        // Check if the binary is unsigned
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        task.arguments = ["--verify", "--strict", binaryPath.path]
        let pipe = Pipe()
        task.standardError = pipe
        try task.run()
        task.waitUntilExit()

        let isUnsigned = task.terminationStatus != 0

        if isUnsigned {
            // CRITICAL: macOS blocks unsigned apps from launching in /Applications.
            // Error: "Launchd job spawn failed" (POSIX error 163).
            // The run.sh script must NOT copy unsigned builds to /Applications.
            //
            // This test documents the constraint. If it fails, either:
            // a) The binary is now signed (update run.sh to allow /Applications), or
            // b) run.sh is incorrectly trying to launch unsigned from /Applications.

            // Verify run.sh doesn't launch from /Applications for unsigned builds
            let runShPath = projectRoot.appendingPathComponent("run.sh")
            let runSh = try String(contentsOf: runShPath, encoding: .utf8)

            // The script should launch from the project directory, not /Applications
            XCTAssertFalse(
                runSh.contains("open \"/Applications/"),
                "run.sh must NOT launch unsigned builds from /Applications — " +
                "macOS blocks unsigned apps there (POSIX error 163). " +
                "Launch from the project directory instead."
            )
            XCTAssertFalse(
                runSh.contains("open \"$INSTALLED\"") && runSh.contains("INSTALLED=\"${INSTALL_DIR}"),
                "run.sh launches from /Applications but binary is unsigned — this will fail"
            )
        }
    }

    func test_runScript_exists_and_isExecutable() {
        let runSh = projectRoot.appendingPathComponent("run.sh")
        XCTAssertTrue(fm.fileExists(atPath: runSh.path), "run.sh must exist")
        XCTAssertTrue(fm.isExecutableFile(atPath: runSh.path), "run.sh must be executable")
    }

    func test_runScript_stripsCodeSignature() throws {
        let runSh = projectRoot.appendingPathComponent("run.sh")
        let content = try String(contentsOf: runSh, encoding: .utf8)

        XCTAssertTrue(
            content.contains("codesign --remove-signature"),
            "Dev builds must strip code signature so Accessibility permission " +
            "persists across rebuilds (macOS tracks by path for unsigned binaries)"
        )
    }

    func test_runScript_launchesFromProjectDirectory() throws {
        let runSh = projectRoot.appendingPathComponent("run.sh")
        let content = try String(contentsOf: runSh, encoding: .utf8)

        // Since we strip the code signature, we MUST launch from the project
        // directory. /Applications rejects unsigned binaries.
        XCTAssertTrue(
            content.contains("open \"$BUNDLE\""),
            "run.sh should launch the local Memo.app bundle (not from /Applications)"
        )
    }
}
