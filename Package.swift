// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-appkit-ui",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AppKitViews", targets: ["AppKitViews"]),
        .library(name: "ThemedControls", targets: ["ThemedControls"]),
        .library(name: "PaneLayout", targets: ["PaneLayout"]),
    ],
    dependencies: [
        .package(path: "../swift-foundation-extensions")
    ],
    targets: [
        .target(
            name: "AppKitViews", dependencies: [.product(name: "FoundationExtensions", package: "swift-foundation-extensions")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
        .target(
            name: "ThemedControls", dependencies: ["AppKitViews"], resources: [.process("Localizable.xcstrings")],
            swiftSettings: [.swiftLanguageMode(.v6), .defaultIsolation(MainActor.self)]),
        .target(name: "PaneLayout", dependencies: ["ThemedControls"], swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "AppKitViewsTests", dependencies: ["AppKitViews"], swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "ThemedControlsTests", dependencies: ["ThemedControls"], swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "PaneLayoutTests", dependencies: ["PaneLayout"], swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
