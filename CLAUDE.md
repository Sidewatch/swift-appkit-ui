# Swift Pane Layout

A split tree of panes and axes for AppKit: `PaneTree<Leaf>` owns the structure, `PaneAxisView`
owns the layout. Module `PaneLayout`; `swift test` is the whole check.

- Swift 6 language mode with main-actor default isolation, tools 6.2, macOS 14+.
- One dependency: swift-themed-controls, for the divider hairline's colour.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.

## Module map

- `Enums/` — PaneOrientation; PaneSplitDirection (carries BOTH decisions a split needs, the axis and the side, so a caller cannot get one of them backwards)
- `Core/` — PaneTree<Leaf: NSView>: the structural mutations (split, remove, collapse), the focus target, the corner
- `Views/` — PaneAxisView (one axis node; the flex vector is the only size truth and layout is arithmetic); PaneDividerView (a 5-pt hit strip drawing a 1-pt hairline; drag resizes, double-click equalises)

## Rules

@CONTRIBUTING.md

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
