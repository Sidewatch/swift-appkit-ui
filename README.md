# Swift AppKit UI

AppKit building blocks for a themed, keyboard-first Mac app: small view behaviours, controls that draw from your palette, and a split-pane tree.

## Modules

Each module is its own library product: depend on the package, then only on the products you use.

| Module | What it is |
|---|---|
| [`AppKitViews`](Docs/Modules/AppKitViews.md) | Small AppKit view behaviours with no palette and no opinions. |
| [`ThemedControls`](Docs/Modules/ThemedControls.md) | AppKit controls that draw from your app's palette instead of the system's: segment bars, pills, fields, row views, scrollers, switches. |
| [`PaneLayout`](Docs/Modules/PaneLayout.md) | A split tree of panes for AppKit, with no `NSSplitView` and no Auto Layout beneath it. |

## Requirements

- macOS 14+
- Swift 6.2+ (Swift 6 language mode)

## Installation

### Swift Package Manager

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

## Usage

### AppKitViews

See [Docs/Modules/AppKitViews.md](Docs/Modules/AppKitViews.md).

### ThemedControls

```swift
import ThemedControls

// Once at launch: install your palette (a value type reading your theme live).
ThemedControls.palette = MyPalette()
// After every theme switch:
NotificationCenter.default.post(name: ThemedControls.paletteDidChange, object: nil)

let bar = ThemedSegmentBar(labels: ["All", "Prompts", "Commands"], symbols: ["square.grid.2x2", "text.bubble", "terminal"])
bar.fillsWidth = true
bar.target = self; bar.action = #selector(filterChanged)
```

### PaneLayout

```swift
let tree = PaneTree<MyPaneView> { MyPaneView() }
tree.container.frame = bounds
addSubview(tree.container)

let first = tree.createRootLeaf()
let second = tree.split(first, .right)        // side by side
let third  = tree.split(second!, .down)       // stacked, inside the right-hand slot
tree.remove(second!)                          // collapses the tree around it
```

Each module's full guide is `Docs/Modules/<Module>.md`.

## Notes

The modules were separate packages until 27 September 2026 (`swift-appkit-views`, `swift-themed-controls`, `swift-pane-layout`); their commits are kept here, so `git log --follow` traces any file back through them.

## For agents

Read `CONTRIBUTING.md` first: the folder layout and the PR rules. `swift test` is the whole
check, and a new test must fail before the change it covers. `CLAUDE.md` / `AGENTS.md` carry a
module map.

## License

MIT — see [LICENSE](LICENSE).
