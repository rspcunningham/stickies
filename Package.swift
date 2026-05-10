// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Stickies",
    platforms: [
        .iOS("18.0"),
        .macOS("26.0")
    ],
    products: [
        .library(name: "StickiesCore", targets: ["StickiesCore"]),
        .executable(name: "Stickies", targets: ["Stickies"])
    ],
    targets: [
        .target(name: "StickiesCore"),
        .executableTarget(
            name: "Stickies",
            dependencies: ["StickiesCore"]
        ),
        .testTarget(
            name: "StickiesCoreTests",
            dependencies: ["StickiesCore"]
        )
    ]
)
