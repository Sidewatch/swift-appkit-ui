// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-appkit-views",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AppKitViews", targets: ["AppKitViews"]),
    ],
    targets: [
        .target(name: "AppKitViews", swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "AppKitViewsTests", dependencies: ["AppKitViews"], swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
