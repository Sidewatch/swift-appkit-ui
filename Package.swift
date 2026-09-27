// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ThemedControls",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ThemedControls", targets: ["ThemedControls"]),
    ],
    dependencies: [
        .package(path: "../swift-appkit-views"),
    ],
    targets: [
        .target(name: "ThemedControls", dependencies: [.product(name: "AppKitViews", package: "swift-appkit-views")], path: "Sources",
                resources: [.process("ThemedControls/Localizable.xcstrings")],
                swiftSettings: [.swiftLanguageMode(.v6), .defaultIsolation(MainActor.self)]),
        .testTarget(name: "ThemedControlsTests", dependencies: ["ThemedControls"], path: "Tests",
                    swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
