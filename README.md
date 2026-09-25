# Swift AppKit Views

Small AppKit view behaviours with no palette and no opinions: an outline that opens as far as it
stays readable, a keyboard walk across a table's editable cells, and a zoomable, pannable image
surface. Module `AppKitViews`; `swift test` is the whole check.

- Swift 6 language mode, tools 6.2, macOS 14+, AppKit only — no dependencies.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.

## What is here

### Outlines

```swift
outline.autoExpand(rowLimit: 400)   // open level by level while the result still fits
outline.expandEveryNode()           // open everything
outline.collapseEveryNode()         // close everything
```

`autoExpand` opens a level **whole or not at all**, so the depth you see is even rather than
depending on which branch the walk reached first, and the first level always opens however large
it is — a tree whose roots are closed says nothing. Both sweeps batch their updates and drop the
row animation: walking row by row re-sets the outline's row map per call, which is quadratic and
measured as a visible stall on a 22,000-row document.

`ExpandableTree` is the protocol a host adopts so one Expand All / Collapse All command can act on
whichever tree is in front without knowing what any of them are showing.

### Tables

```swift
extension MyTable: CellTabbing {
    var editableCells: [CellPosition] { … }        // reading order
    func beginEditing(_ position: CellPosition) { … }
}
if let next = table.cell(after: here, forward: true) { table.beginEditingWhenReady(next) }
```

AppKit's key-view loop does not join up text fields inside table rows, so Tab out of one commits
it and lands somewhere else entirely. The table answers where its editable cells are and this
walks them. Two rules are deliberate: the walk **stops at both ends** rather than wrapping, so a
held Tab cannot silently start over at the top; and `beginEditingWhenReady` retries once, because
committing an edit usually rebuilds the rows and throws away the view the move was aimed at.

### Images

```swift
let scroll = ZoomingScrollView()
scroll.contentView = CenteringClipView()
scroll.documentView = PannableImageView()
scroll.allowsMagnification = true
```

The wheel zooms at the pointer on **every** device — precise trackpad deltas smoothly, wheel
detents in clamped steps — the clip view keeps a small document centred rather than in the
bottom-left corner, and the image view pans under a drag with the hand cursor. `ZoomKeyView` is a
container that answers ⌘= / ⌘- / ⌘0 before the main menu, so its content zooms while it is on
screen and a menu item bound to the same keys keeps working when it is not.

## Notes worth knowing

- `allowsMagnification` governs **programmatic** magnification too. With it false, assigning
  `magnification` is silently ignored — size the document to the viewport instead.
- `ZoomKeyView.menu(for:)` returns an **empty** menu, never nil. Returning nil lets a right-click
  climb the responder chain to whatever sits beneath, which is how a text editor's Cut / Go to
  Definition menu ends up opening over an image.
- Measure an outline **in a window**. Detached, `NSOutlineView` takes a pathological path through
  its row bookkeeping — the same 22,764-row sweep costs 0.70 s / 4.85 s detached against
  0.030 s / 0.019 s hosted.

## Licence

MIT.
