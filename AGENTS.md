# Swift AppKit UI

AppKit building blocks for a themed, keyboard-first Mac app: small view behaviours, controls that draw from your palette, and a split-pane tree.

- Modules `AppKitViews`, `ThemedControls`, `PaneLayout`, each in `Sources/<Module>` with tests in `Tests/<Module>Tests`; `swift test` is the whole check.
- Swift 6 language mode, tools 6.2, macOS 14+.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.
- Each module's user-facing documentation is `Docs/Modules/<Module>.md`; its last audit is `Docs/Audits/<Module>.md` — read it before auditing, and extend it rather than redo it.

## AppKitViews — `Sources/AppKitViews`

### Module map
- `Core/` — ImageComparisonLayout (fit, the two panes, the divider's place); NavigationHistory (two stacks, not a cursor: a new jump BRANCHES, so the forward path is cleared rather than silently rejoinable), RecentOrder (most-recently-used by a STABLE id — never an object address, which is reused), TabSelection (the selected index through a move and a close; the successor is a policy: right neighbour, or most recent else left); ZoomStep (the 1.25 step and the fit scale); TabStripLayout (a strip of tabs: origins at rest and while one is dragged, the tab under a point, the drop slot past each midpoint, the least scroll that reveals a tab); EdgeDrag (a pane's size while its edge is dragged, by direction, clamped)
- `Enums/` — ImageComparisonMode (side by side, swipe, changes); ZoomKeyDirection (⌘= / ⌘- / ⌘0 → in / out / actual; `nil` for any other key, so a caller can hand the event straight on); EdgeDragDirection (up, down, left, right — window coordinates, y upward)
- `Models/` — ImageComparisonColors; CellPosition; DocumentLocation (a file and a range, captured at jump time and never revalidated) (a row and a field tag; a POSITION rather than a view, because committing an edit usually rebuilds the rows)
- `Protocols/` — ExpandableTree (a view whose content is a tree, so one command can act on whichever is in front); CellTabbing (a table whose editable cells Tab walks; the extension carries the walk, the retry and the first-responder test)
- `Extensions/` — NSMenu+Separators (`hideRedundantSeparators`: after items hide, no separator first, last or twice in a row, and the rest shown again — call it after every change); NSMenuItem+KeyEquivalent (`KeyCombo`: a shortcut normalized — the Shift a capital key implies folded in — and drawn as the menu bar draws it, arrows and F-keys included; `keyCombo` / `keyEquivalentDisplay`); NSTextView+ScrollHosting (`configureForVerticalScrolling()`: the min/max size, resizing, autoresizing and container-tracking a text view built over its own container needs to grow and wrap inside a scroll view); NSPasteboard+Drops (one drop flow for files, raw image bytes, file promises and links; the callback is `@MainActor` and may run more than once); NSOutlineView+Expansion (autoExpand / expandEveryNode / collapseEveryNode, all batched with the row animation off); NSTableView+ReusableView (`reusableView(variant:_:)`: every row-view factory returns through it, because a row view built afresh per call stays in the table's row-view purgatory for good once it scrolls off screen; a cell replaced while its row stays comes through it too, or the row keeps three AppKit dependency records per cell it ever hosted); NSScrollView+Zoom (`stepMagnification`, `fitMagnification(to:allowEnlarge:)` against `fittingContentSize` — the area the scrollers leave, so ⌘0 fits the same way on every press); NSView+KeyboardFocus (`containsKeyboardFocus`: the first responder is the view or inside it); NSColor+Contrast (`contrastRatio`, `relativeLuminance`, `textOnTop`: soft black on a light fill, else white); NSPasteboard+Drops (`dropsDirectory(unique:)` public: a host's own files beside dropped ones)
- `Support/` — FlowLayout; LateToolTip (a tooltip over a view's bounds whose words are asked for only as it shows — for text that costs a process or a read; follows resizes; adds and removes only its own rectangle; the caller keeps it, AppKit does not)
- `Views/` — CompanionWindowController (a window that BORROWS a view — a panel torn off for another screen — and gives it back with `release()`; the red button asks `onCloseRequest` instead of closing, so the view is never lost with a window nobody holds; `frameDescriptor` for the host to keep), ImageComparisonView (two versions of a picture: side by side with captions, swiped by a divider the pointer drags or ←/→ moves, or the changed pixels drawn over the dimmed after; fitted with the shape kept and enlarged up to 16×, drawn without smoothing over a checkerboard; colours from `ImageComparisonColors`, geometry in `Core/ImageComparisonLayout`), ZoomingScrollView (the wheel zooms at the pointer on every device), CenteringClipView (a small document sits centred), PannableImageView (drag-to-pan with the hand cursor); ZoomKeyView (answers the zoom keys before the menu; `open`, since a host may subclass it); RecyclingOutlineView (`open`: every outline uses it, because a plain `NSOutlineView` keeps every disclosure button it builds, one per expandable row per reload)

### Rules of this module
- **Measure an outline IN A WINDOW.** Detached, `NSOutlineView` takes a pathological path through
  its row bookkeeping: the same 22,764-row sweep measured 0.70 s / 4.85 s detached against
  0.030 s / 0.019 s hosted — a 250× difference entirely in the rig. A detached measurement would
  condemn correct code, and a bound loose enough to pass detached could never catch a regression.
- **The COST of the sweeps is pinned by Sidewatch's `--selftest-config-views`, not here.** Hosted
  in a bare window the unbatched per-row walk measures as fast as the batched one, so any bound
  this package could assert would pass against the quadratic version too — a check that cannot
  fail, implying coverage that is not there. The batching stays because it was measured where it
  matters: 0.39 s open / 0.71 s close on a 22,000-row document per-row, against 0.21 s / 0.24 s.
- **`expandEveryNode` is ONE call, and the repeat it used to carry is not coming back.** It was a
  sweep repeated until the row count settled, justified as reaching a lazily-built tree. Tested
  26 Sep 2026: AppKit queries each newly opened node as it goes, so any source that answers its
  children when asked is fully reached in one pass, and a source that answers zero on the first
  ask is not opened by repeating either. No test could be written that the loop fixed.
- **`allowsMagnification` governs programmatic magnification too** — with it false, a
  `magnification` assignment is silently ignored.
- **A container over other content returns an EMPTY menu from `menu(for:)`, never nil.** Nil lets
  the right-click climb to whatever sits beneath.
- A class the host may subclass is `open` with `open` members; everything else is `public final`.
- **A width-to-height view reports its height from `setFrameSize`, never from `layout()`, and
  only at DISCRETE breakpoints.** Invalidating inside `layout()` re-dirties the view mid-pass and
  a continuous resize never converges, which AppKit aborts as "more layout passes than there are
  views".
- **A callback that a background queue delivers is `@MainActor`, not `@Sendable`.** A `@Sendable`
  sink forces every caller to build a thread-safe box for a value that was always going to arrive
  on main. `NSPasteboard.readDroppedFiles` hops and declares the hop.

## ThemedControls — `Sources/ThemedControls`

### Module map
- `Protocols/` — protocols the module exposes: ControlPalette (what a control reads from the theme)
- `Core/` — the engine: ThemedControls (the installed palette and the paletteDidChange notification)
- `Controls/` — one control per file: ThemedActionButton (a guide's Continue / Back / Skip: the accent capsule or plain text, a symbol on either side), ChoiceCardView (a described choice ringed in the accent while picked; click, Space or VoiceOver's press; the host keeps the group), PathBarView (a path as crumbs, each dropping its folder; the HOST supplies the listing and the icons, so hidden files, ignore rules and sort order stay one decision made wherever the app already shows that tree), ThemedSegmentBar, ThemedPillButton, ThemedIconButton (a bar's SF Symbol button: clear at rest, a soft fill under the pointer, the accent while on), ThemedSlider, ThemedSwitch (`controlSize` sizes it like the stock switch), ThemedCheckbox, ThemedSearchField, ThemedInputField, ThemedRowView, ThemedScrollView, EmptyStateView, LoadingStateView (a spinner and caption shown only once a load outlasts its delay, so a fast read never flashes it; both states `install(over:)` a list through the shared NSView+CoverHost), ThemedPopUpButton, ThemedStepperField (a number and its up/down arrows in the pop-up's box and height, grouped, clamped, repeating while held; typed junk puts the last value back), ThemedTableHeaderView, ThemedTableHeaderCell, InnerGridTableView (vertical grid lines BETWEEN columns only — the stock mask rules the table's outer edges too, which frames it rather than dividing it) (secondary types alongside: ThemedInputStyle, PaddedFieldCell, ThemedSelectionRowView, ThemedGroupRowView)
- `Onboarding/` — StepFlow (a guide's position and moves as a value: no Back from the first step, Continue on the last finishes, Skip from anywhere, nothing once finished), StepFlowStep, StepFlowView (one page at a time under its symbol tile and heading, with Back / Skip / Continue-or-Done, Return and Escape; laid out for `preferredSize`, a page fills `pageWidth`; a move after the end does nothing, so the end is reported once), StepDotsView (the current dot long; it carries the "Step 2 of 4" label)
- `Settings/` — the settings-form pieces, including SettingsSectionsView (sections down a column at any width; `buildPane` puts one in its scrolling page), SettingsRowView's `symbol:` (a SymbolTileView before the caption, `Views/`), SettingsWordListView (a one-word-per-row list with +/− and Restore Defaults; `setWords` loads it without calling `onChange`); SettingsDefaultsRestoring (a page that can restore its own settings; `buildPane` ends it with a SettingsRestoreDefaultsButton, which asks in a sheet, then calls `restoreDefaults()` and `syncFromSettings()`); ThemedSlider+Settings (`configureAsSettingsValue`: a continuous small 150 pt slider whose ticks are a scale cue; `styleAsSliderReadout(width:)`: the fixed-width value beside it); the window shell: SettingsSidebarView (the page list; a programmatic move is silent, a re-theme keeps the page without reporting a pick), SettingsSidebarCell, SettingsSidebarRowView (the accent fill; `ControlPalette.onAccent` reads on it), SettingsPageView
- `Support/` — pure helpers: SystemPalette (the macOS system colours as a palette); CellEditFormatter (what a cell DRAWS against what it EDITS — quotes, a trailing colon, a `••••••••` mask; a `Formatter`, because swapping a field's `stringValue` in `controlTextDidBeginEditing` does NOT reach the field editor AppKit has already loaded, and the edit is read from `objectValue`)
- AppKit helpers (`NSColor.blended`, `NSImage.tinted`, the text-intelligence policy) come from AppKitViews.

### Rules of this module
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
- **A path bar must NOT probe the file system to decide what a crumb is.** `PathSegment` carries
  `isDirectory` because the host knows it. Probing means touching the disk on the main thread
  every time a menu opens, and makes the answer depend on whether the path happens to exist —
  a crumb for a just-deleted file would silently change what its menu shows.
- **A separator in a crumb strip is MARKED, not recognised by its text.** A crumb legitimately
  named "›" would otherwise be skipped by every restyle.
- **`pageBackground` and `cardBackground` have protocol defaults so old palettes compile**, but a
  host drawing settings forms must answer them properly: a card the same colour as its page is
  not a card.

  against the palette colour rendered through the SAME path, never against its hex — colour spaces differ.

## PaneLayout — `Sources/PaneLayout`

### Module map
- `Support/` — FlexVector (`isValid`: count, every share positive, the sum; `keeping`: survivors of dropped members keep their proportions). `setFlexes` validates and refuses an invalid vector.
- `Enums/` — PaneOrientation; PaneSplitDirection (carries BOTH decisions a split needs, the axis and the side, so a caller cannot get one of them backwards)
- `Core/` — PaneTree<Leaf: NSView>: the structural mutations (split, remove, collapse), the focus target, the corner
- `Views/` — PaneAxisView (one axis node; the flex vector is the only size truth and layout is arithmetic); PaneDividerView (a 5-pt hit strip drawing a 1-pt hairline; drag resizes, double-click equalises)

### Rules of this module
- **NO `NSSplitView` and NO Auto Layout on members.** Members keep
  `translatesAutoresizingMaskIntoConstraints == true` and only ever receive frames. Layout is a
  pure function of the flex vector, which is what makes the resize feedback loop impossible by
  construction rather than by care. An `NSSplitView` attempt was reverted for exactly that crash.
- **The flex vector is the only size truth:** `flexes.count == members.count`, summing to
  `members.count`, asserted after every mutation.
- **`replaceMember` must NOT reset the flexes** — the whole point of replacing in place is that
  the replacement inherits the slot's fraction. `insertMember` and `removeMember` do reset.
- **The last member takes the rounding remainder**, or frames stop tiling exactly at awkward
  widths.
- **A test for flex preservation must use UNEVEN flexes.** With equal shares a remove-and-
  reinsert looks identical to a replace, so the check cannot fail. That exact mistake was made
  and caught by mutation testing on 26 Sep 2026.
- **The debug invariants are load-bearing.** Breaking the collapse rule does not produce a test
  failure, it produces SIGTRAP from `assertTreeInvariants` — a signal 5 in a test run means an
  invariant fired, not a crash to debug elsewhere.
- **Auditing? Read `AUDIT.md` first.**

## Rules

Read `CONTRIBUTING.md` for the folder layout and the pull-request rules.

@CONTRIBUTING.md
