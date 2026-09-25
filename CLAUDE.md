# Swift Themed Controls

AppKit controls drawn from a host-supplied palette. Module `ThemedControls`; `swift test` is the whole check.

- Swift 6 language mode with main-actor default isolation, tools 6.2, macOS 14+, AppKit only — no dependencies.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.

## Module map

- `Protocols/` — protocols the module exposes: ControlPalette (what a control reads from the theme)
- `Core/` — the engine: ThemedControls (the installed palette and the paletteDidChange notification)
- `Controls/` — one control per file: ThemedSegmentBar, ThemedPillButton, ThemedSlider, ThemedSwitch (`controlSize` sizes it like the stock switch), ThemedCheckbox, ThemedSearchField, ThemedInputField, ThemedRowView, ThemedScrollView, EmptyStateView, ThemedPopUpButton, ThemedTableHeaderView, ThemedTableHeaderCell, InnerGridTableView (vertical grid lines BETWEEN columns only — the stock mask rules the table's outer edges too, which frames it rather than dividing it) (secondary types alongside: ThemedInputStyle, PaddedFieldCell, ThemedSecureInputField, ThemedSelectionRowView, ThemedGroupRowView)
- `Support/` — pure helpers: SystemPalette (the macOS system colours as a palette); CellEditFormatter (what a cell DRAWS against what it EDITS — quotes, a trailing colon, a `••••••••` mask; a `Formatter`, because swapping a field's `stringValue` in `controlTextDidBeginEditing` does NOT reach the field editor AppKit has already loaded, and the edit is read from `objectValue`)
- `Extensions/` — one extension per idiom: NSColor+Blend, NSImage+Tinted, NSTextView+SystemTextIntelligence, NSTextView+WritingTools

## Rules

@CONTRIBUTING.md

- A control reads `ThemedControls.palette` at draw time and observes `ThemedControls.paletteDidChange`; it never caches a colour across a theme switch.
- **`FontCatalog`'s two halves must stay apart.** Enumeration walks a family's members through
  `NSFontManager` — fine in a settings pane, ruinous anywhere else, because a host's editor-font
  accessor is called once per line number while a gutter draws and resolving a family through the
  font system there measured 349 ms in a sampled stall. A pane resolves a chosen weight to its
  PostScript name ONCE, at the click; the render path only ever does an exact `NSFont(name:)` and
  is `nonisolated` so background callers can use it at all.
- **Its fallback ORDER is a decision:** a stale PostScript name keeps the FAMILY and drops to its
  default face, because the family is much the bigger part of what the user chose. Only a missing
  family falls all the way back to the system font.
- Classes the host may subclass are `open` with `open` overridable members; everything else is `public final`.
- Layout must degrade: a label that does not fit is shortened or dropped, never overlapped (`ThemedSegmentBar.content(for:width:)` is the model).
- A cell that draws its own background must also drop `isHighlighted` around `drawInterior` — AppKit's cells paint
  the system pressed fill from there, which lands on top of the palette one (`ThemedTableHeaderCell`).
- Pixel tests render the view and sample the bitmap: sample in POINTS (the rep is at backing scale) and compare
- **Auditing? Read `AUDIT.md` first** — what the last full audit checked and fixed, and the known non-issues to skip; extend it, do not redo it.
  against the palette colour rendered through the SAME path, never against its hex — colour spaces differ.
