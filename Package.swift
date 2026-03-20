// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhisperInput",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        // All app logic as a library so tests can import it.
        .target(
            name: "WhisperInput",
            path: "Sources/WhisperInput"
        ),
        // Thin entry point — calls WhisperInputApp.main().
        .executableTarget(
            name: "WhisperInputMain",
            dependencies: ["WhisperInput"],
            path: "Sources/WhisperInputMain"
        ),
        .testTarget(
            name: "WhisperInputTests",
            dependencies: ["WhisperInput"],
            path: "Tests/WhisperInputTests"
        )
    ]
)
