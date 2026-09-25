// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-pane-layout",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PaneLayout", targets: ["PaneLayout"]),
    ],
    dependencies: [
        .package(path: "../swift-themed-controls"),
    ],
    targets: [
        .target(name: "PaneLayout",
                dependencies: [.product(name: "ThemedControls", package: "swift-themed-controls")],
                swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "PaneLayoutTests", dependencies: ["PaneLayout"], swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
