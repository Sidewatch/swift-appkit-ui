# Swift AppKit Views

Small AppKit view behaviours with no palette: outline expansion, a Tab walk across a table's
editable cells, and a zoomable/pannable image surface. Module `AppKitViews`; `swift test` is the
whole check.

- Swift 6 language mode with main-actor default isolation, tools 6.2, macOS 14+, AppKit only — no dependencies.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.

## Module map

- `Core/` — NavigationHistory (two stacks, not a cursor: a new jump BRANCHES, so the forward path is cleared rather than silently rejoinable)
- `Enums/` — ZoomKeyDirection (⌘= / ⌘- / ⌘0 → in / out / actual; `nil` for any other key, so a caller can hand the event straight on)
- `Models/` — CellPosition; DocumentLocation (a file and a range, captured at jump time and never revalidated) (a row and a field tag; a POSITION rather than a view, because committing an edit usually rebuilds the rows)
- `Protocols/` — ExpandableTree (a view whose content is a tree, so one command can act on whichever is in front); CellTabbing (a table whose editable cells Tab walks; the extension carries the walk, the retry and the first-responder test)
- `Extensions/` — NSPasteboard+Drops (one drop flow for files, raw image bytes, file promises and links; the callback is `@MainActor` and may run more than once); NSOutlineView+Expansion (autoExpand / expandEveryNode / collapseEveryNode, all batched with the row animation off)
- `Views/` — ZoomingScrollView (the wheel zooms at the pointer on every device), CenteringClipView (a small document sits centred), PannableImageView (drag-to-pan with the hand cursor), CardGridView (reflows its column count with its width); ZoomKeyView (answers the zoom keys before the menu; `open`, since a host may subclass it)

## Rules

@CONTRIBUTING.md

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
  views". `CardGridView` re-invalidates only when its column count changes.
- **A callback that a background queue delivers is `@MainActor`, not `@Sendable`.** A `@Sendable`
  sink forces every caller to build a thread-safe box for a value that was always going to arrive
  on main. `NSPasteboard.readDroppedFiles` hops and declares the hop.
- **Auditing? Read `AUDIT.md` first** — what the last audit checked and the known non-issues.
