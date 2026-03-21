// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Memo",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "Memo",
            path: "Sources/Memo",
            resources: [
                .process("Resources"),
            ]
        ),
        .executableTarget(
            name: "MemoMain",
            dependencies: ["Memo"],
            path: "Sources/MemoMain"
        ),
        .testTarget(
            name: "MemoTests",
            dependencies: ["Memo"],
            path: "Tests/MemoTests"
        )
    ]
)
