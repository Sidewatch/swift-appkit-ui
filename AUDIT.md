# Audit trail

What a full audit of this package checks, what the last one found, and the known non-issues to
skip. Extend this file; do not redo work recorded here.

## Extraction and first audit — 26 September 2026

These types came out of Sidewatch, where they had accumulated in the app's `Previews/` folder.
Every one is generic AppKit with no palette, no window ownership and no app type in its
signature, which is what made them extractable under the family's thin-layer rule.

### Found and fixed during the move

- **`expandEveryNode`'s repeat loop was removed.** It swept until the row count settled, on the
  stated grounds that `expandItem(nil, expandChildren: true)` only walks what the data source has
  already been asked about. A lazy fixture was written to pin that, and it showed the opposite:
  AppKit queries each newly opened node as it goes, so a source that answers its children when
  asked is fully reached in ONE pass — and a source that answers zero on the first ask is not
  opened by repeating either, because the row count does not change and the loop exits. The loop
  was defensive code for a case that does not exist, and the mutation test proved it: making it
  single-pass failed no test. It is one call now.
- **Seven dead imports per file.** The four view files each carried `DataConverter`, `WebKit`,
  `AVKit`, `PDFKit`, `CodeLanguage` and `CodeHighlighting` — residue from a one-type-per-file
  split in the app, none of them used. AppKit alone now.
- **`ZoomKeyDirection.swift` carried the wrong doc comment**, describing the scroll view and
  claiming "trackpads keep their native behaviour — two-finger scroll scrolls", which the scroll
  view had explicitly stopped doing. Rewritten to describe the enum.
- **The app's `clamped(to:)` dependency was inlined** rather than copied, so the package needs no
  helper extension and cannot collide with a host's own.

### The rig lesson, which is the important one

`NSOutlineView` measured **detached from a window** is not the same view. On the same 22,764-row
tree and the same code:

| | expand | collapse |
|---|---|---|
| detached | 0.696 s | 4.846 s |
| in a window | 0.030 s | 0.019 s |

The test fixture hosts the outline in a window for this reason. A detached measurement here would
have condemned correct code by a factor of 250.

### Deliberately NOT asserted here

The **cost** of the sweeps. Hosted in a bare window with no cell views, the unbatched per-row walk
measures as fast as the batched one, so no bound this rig can state would fail against the
quadratic version — a check that cannot fail implies coverage that is not there. Sidewatch's
`--selftest-config-views` pins it against a real tree with real cells and fails over half a
second. The batching stays on that evidence (0.39 s / 0.71 s per-row against 0.21 s / 0.24 s).

### Mutation verification

34 tests. Every behaviour was broken deliberately and the failure confirmed:

| mutant | tests that failed |
|---|---|
| the cell walk wraps instead of stopping | `testTabStopsAtBothEndsRatherThanWrapping`, `testASingleCellTableHasNowhereToGo` |
| precise deltas passed to `super` (the trackpad bug) | `testPreciseTrackpadDeltasZoomToo` |
| no detent clamp | `testOneEventCannotCrossTheWholeRange` |
| `menu(for:)` returns nil | `testARightClickYieldsAnEmptyMenuRatherThanNil` |
| the zoom keys claim any modifier combination | `testOtherModifierCombinationsAreNotClaimed` |
| the clip view does not centre | `testASmallerDocumentIsCentredOnBothAxes`, `testOnlyTheAxisWithRoomIsCentred` |
| `autoExpand` applies its limit to level 0 | `testAutoExpandAlwaysOpensTheFirstLevel` |
| `expandEveryNode` made single-pass | **none — which is why the loop was removed** |

## Known non-issues

- `ZoomingScrollViewTests` builds a stub `NSEvent` subclass to report a scrolling delta, because
  `NSEvent` cannot be constructed with one. It is fine for every path that does NOT reach
  `super.scrollWheel`; the zero-delta case does reach it and therefore uses a real `CGEvent`, or
  AppKit raises "Unrecognized event type 0".
- `CellTabbing.isEditing(_:)` ignores its argument's `tag` and asks only whether a field of this
  view holds the keyboard. That is what the retry needs, and narrowing it would require the host
  to expose its field views.
