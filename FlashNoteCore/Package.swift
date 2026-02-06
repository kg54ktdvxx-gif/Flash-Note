// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FlashNoteCore",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v15)
    ],
    products: [
        .library(name: "FlashNoteCore", targets: ["FlashNoteCore"])
    ],
    targets: [
        .target(
            name: "FlashNoteCore",
            path: "Sources/FlashNoteCore"
        ),
        .testTarget(
            name: "FlashNoteCoreTests",
            dependencies: ["FlashNoteCore"],
            path: "Tests/FlashNoteCoreTests"
        )
    ]
)
