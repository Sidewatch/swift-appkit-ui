# Swift AppKit UI

AppKit building blocks for a themed, keyboard-first Mac app: small view behaviours, controls that draw from your palette, and a split-pane tree.

## Modules

Each module is its own library product: depend on the package, then only on the products you use.

| Module | What it is |
|---|---|
| [`AppKitViews`](Docs/Modules/AppKitViews.md) | Small AppKit view behaviours with no palette and no opinions. |
| [`ThemedControls`](Docs/Modules/ThemedControls.md) | AppKit controls that draw from your app's palette instead of the system's: segment bars, pills, fields, row views, scrollers, switches. |
| [`PaneLayout`](Docs/Modules/PaneLayout.md) | A split tree of panes for AppKit, with no `NSSplitView` and no Auto Layout beneath it. |

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/Sidewatch/swift-appkit-ui.git", from: "0.1.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "AppKitViews", package: "swift-appkit-ui"),
    ]),
]
```

## Requirements

- macOS 14+
- Swift 6.2+ (Swift 6 language mode)

## History

The modules were separate packages until 27 September 2026 (`swift-appkit-views`, `swift-themed-controls`, `swift-pane-layout`); their commits are kept here, so `git log --follow` traces any file back through them.

## Licence

MIT — see [LICENSE](LICENSE).
