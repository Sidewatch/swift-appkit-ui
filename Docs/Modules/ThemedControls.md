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
    .package(url: "https://github.com/Sidewatch/swift-appkit-ui.git", from: "0.1.0")
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
- `ThemedIconButton` — a bar's SF Symbol button (22 pt, or any `side`): no bezel at rest, a soft rounded fill under the pointer and a deeper one pressed, the accent glyph and a faint accent fill while `isOn`; `restingTint` overrides the glyph colour at rest.
- `ThemedSlider` — an `NSSlider` whose filled track is the palette accent (knob and ticks stay the system's).
- Accessibility: `ThemedSegmentBar` is a VoiceOver radio group whose segments press, and ← → move its selection under Full Keyboard Access; `ThemedSwitch` reads as a switch, toggles on Space, and snaps instead of sliding when `ThemedControls.reduceMotion` is on (the host mirrors System Settings ▸ Accessibility ▸ Reduce Motion into it).
- `ThemedSwitch` — an on/off switch drawn from the palette (`NSSwitch` fills with the macOS accent and cannot be tinted): `state`, `target`/`action`, `isEnabled`, the stock footprint, click and Space, a 0.18 s slide, VoiceOver switch role.
- `ThemedSearchField`, `ThemedInputField` — fields with a themed border and placeholder.
- `ThemedStepperField` — a number with up and down arrows in `ThemedPopUpButton`'s box and height (24 pt at 13 pt): grouped (`formatter`), clamped to `minValue`…`maxValue`, stepped by `increment` from the arrow halves (repeating while held) or ↑/↓ while typing; typed junk puts the last value back; every change the person makes sends `action` to `target`.
- `ThemedRowView`, `ThemedSelectionRowView`, `ThemedGroupRowView` — `NSTableRowView`s with the palette's selection and separators.
- `ThemedTableHeaderView` + `ThemedTableHeaderCell` — a table header in the palette: band, bottom hairline,
  column divider, title and pressed state. Use BOTH — the view alone leaves the stock cell painting a system
  background over it — and the cell keeps the sort indicator a plain `draw(withFrame:in:)` override loses.
- `ThemedScrollView` — overlay scrollers whose knob follows the palette's appearance.
- `EmptyStateView` — symbol, title, subtitle, a primary action and any number of secondary ones beneath it (`show(…secondary:)`), centred.
- `InnerGridTableView` — a table whose vertical grid lines fall between columns and never on its own leading or trailing edge. `NSTableView.solidVerticalGridLineMask` rules every boundary including the outer two, so the first column wears a line down its left where nothing is being divided. Set `gridStyleMask = [.solidHorizontalGridLineMask]` and this draws the rest.
- `CellEditFormatter` — what a table or outline cell **draws** against what it **edits**: a string as `"nginx"`, a tree key as `image:`, a secret as `••••••••`, each typed over as the bare value. It is a `Formatter` because swapping a field's `stringValue` inside `controlTextDidBeginEditing` does NOT reach the field editor AppKit has already loaded, so the decoration would be edited into the value (a quoted value re-quoted on every double-click). Set `field.formatter` and `field.objectValue`, and read the edit back from `objectValue`, never `stringValue`.
- `ThemedActionButton` — a larger button for moving on: `.primary` is an accent-filled capsule with `onAccent` text, `.plain` the title alone in the muted tone, brightening under the pointer; an optional SF Symbol before (`‹ Back`) or after (`Continue ›`) the title.
- `SettingsRowView(_:control:footnote:symbol:)` — with `symbol`, the row carries the symbol on an accent-tinted tile before its caption, as System Settings marks rows.
- `SettingsSectionsView` — sections down a column at whatever width it is given (`buildPane` puts one in its scrolling page; a guide page uses one directly).
- `ChoiceCardView` — one of a few described choices: an SF Symbol, a name and a wrapped line of detail on the card fill, ringed in the accent while `isPicked`. A click, Space or VoiceOver's press calls `onPick`; the host sets `isPicked` on every card of the group. VoiceOver reads a radio button.

## Step-by-step guides

`StepFlowView` shows `StepFlowStep` pages one at a time — an SF Symbol on an accent tile beside a heading and its line, and a controller's view (a `SettingsSectionsView` makes a guide's rows the app's own Settings rows) — over a footer of `‹ Back`, a dot per step (the current one long; VoiceOver reads "Step 2 of 4"), `Skip` and the accent `Continue ›` (`Done ✓` on the last page). It is laid out for `StepFlowView.preferredSize`; a page fills `pageWidth`, which wrapping text in a page sizes itself from. Return continues, Escape skips, and `onFinish` reports `.completed` or `.skipped` once. `StepFlow` is the position and its moves as a plain value, tested without a window.

```swift
let guide = StepFlowView(steps: [
    StepFlowStep(title: "Welcome", subtitle: "Pick a theme.", symbol: "paintpalette", content: themePage),
    StepFlowStep(title: "The editor", subtitle: "What the editor shows.", symbol: "character.cursor.ibeam", content: editorPage),
])
guide.onFinish = { ending in window.close() }
```

The view owns no settings: a page's controls show the current values and write their own, so every page is optional.

## For agents

See `CLAUDE.md` for the module map and `CONTRIBUTING.md` for the rules a PR is held to.
