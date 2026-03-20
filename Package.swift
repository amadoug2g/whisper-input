// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhisperInput",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "WhisperInput",
            path: "Sources/WhisperInput",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)
