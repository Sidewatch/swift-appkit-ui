# Swift Themed Controls

AppKit controls that draw from **your app's palette** instead of the system's: a segment bar, pill button, search and input fields, table row views, a scroll view with a themed scroller, a checkbox and an empty-state view. The stock controls paint a system bezel and selection that ignore a custom theme; these read live from one `ControlPalette` and repaint on a notification, so a theme switch is one repaint away.

- Module `ThemedControls` in `Sources/ThemedControls`; tests in `Tests`; `swift test` is the whole check.
- Swift 6 language mode with main-actor default isolation, tools 6.2, macOS 14+, AppKit only.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.

## Requirements

- macOS 14+
- Swift 6.2+ (Swift 6 language mode)

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Sidewatch/swift-themed-controls.git", from: "0.1.0")
]
```

## Usage

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

`ControlPalette` is the whole contract: a handful of colours, the small font, and `elevatedSurface(dark:light:)`. `SystemPalette` (the macOS system colours) is installed until you replace it, so a control never draws blank.

## Controls

- `ThemedSegmentBar` — equal-width or hugging segments with SF Symbols; shortens or drops labels that do not fit; redraws while resized.
- `ThemedPillButton`, `ThemedCheckbox` — accent-filled controls (`open`, subclassable); a disabled pill dims to 40%.
- `ThemedSlider` — an `NSSlider` whose filled track is the palette accent (knob and ticks stay the system's).
- Accessibility: `ThemedSegmentBar` is a VoiceOver radio group whose segments press, and ← → move its selection under Full Keyboard Access; `ThemedSwitch` reads as a switch, toggles on Space, and snaps instead of sliding when `ThemedControls.reduceMotion` is on (the host mirrors System Settings ▸ Accessibility ▸ Reduce Motion into it).
- `ThemedSwitch` — an on/off switch drawn from the palette (`NSSwitch` fills with the macOS accent and cannot be tinted): `state`, `target`/`action`, `isEnabled`, the stock footprint, click and Space, a 0.18 s slide, VoiceOver switch role.
- `ThemedSearchField`, `ThemedInputField`, `ThemedSecureInputField` — fields with a themed border and placeholder.
- `ThemedRowView`, `ThemedSelectionRowView`, `ThemedGroupRowView` — `NSTableRowView`s with the palette's selection and separators.
- `ThemedTableHeaderView` + `ThemedTableHeaderCell` — a table header in the palette: band, bottom hairline,
  column divider, title and pressed state. Use BOTH — the view alone leaves the stock cell painting a system
  background over it — and the cell keeps the sort indicator a plain `draw(withFrame:in:)` override loses.
- `ThemedScrollView` — overlay scrollers whose knob follows the palette's appearance.
- `EmptyStateView` — symbol, title, subtitle and up to two actions, centred.
- `InnerGridTableView` — a table whose vertical grid lines fall between columns and never on its own leading or trailing edge. `NSTableView.solidVerticalGridLineMask` rules every boundary including the outer two, so the first column wears a line down its left where nothing is being divided. Set `gridStyleMask = [.solidHorizontalGridLineMask]` and this draws the rest.
- `CellEditFormatter` — what a table or outline cell **draws** against what it **edits**: a string as `"nginx"`, a tree key as `image:`, a secret as `••••••••`, each typed over as the bare value. It is a `Formatter` because swapping a field's `stringValue` inside `controlTextDidBeginEditing` does NOT reach the field editor AppKit has already loaded — a shipped build quoted a value again on every double-click that way, writing to a file nobody had edited. Set `field.formatter` and `field.objectValue`, and read the edit back from `objectValue`, never `stringValue`.

## For agents

See `CLAUDE.md` for the module map and `CONTRIBUTING.md` for the rules a PR is held to.
