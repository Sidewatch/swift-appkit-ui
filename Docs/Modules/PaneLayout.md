# Swift Pane Layout

A split tree of panes and axes for AppKit, with no `NSSplitView` and no Auto Layout beneath it.
Module `PaneLayout`; `swift test` is the whole check.

- Swift 6 language mode, tools 6.2, macOS 14+, AppKit. One dependency, `ThemedControls`, for the divider's colour.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.

## Usage

```swift
let tree = PaneTree<MyPaneView> { MyPaneView() }
tree.container.frame = bounds
addSubview(tree.container)

let first = tree.createRootLeaf()
let second = tree.split(first, .right)        // side by side
let third  = tree.split(second!, .down)       // stacked, inside the right-hand slot
tree.remove(second!)                          // collapses the tree around it
```

`PaneTree` is generic over the leaf, so `panes`, `split` and `focusedPane` give your own type
back rather than `NSView`s to cast.

## The rules, and why each one matters

- **A same-axis split INSERTS.** Splitting right inside a horizontal run adds a fourth member to
  that run, so the tree stays flat instead of growing a spine of two-member axes. One set of
  dividers then rules the whole run.
- **A cross-axis split WRAPS in place.** The parent's members and flex vector are untouched, so
  the wrapper inherits the slot's fraction. Removing and re-inserting instead loses it.
- **Any membership change resets that axis to equal shares.** Only that axis.
- **An axis left with one member pops it into the parent slot**, keeping the slot's fraction, or
  becomes the root. A popped axis matching the parent's orientation is spliced flat.
- **Removing an unfocused leaf does not move the focus target.** A pane whose work finished on
  its own in the background must not steal where your next split lands.

## Layout

An axis holds a **flex vector**, which is the only size truth: `flexes.count == members.count`
and they sum to `members.count`. Layout is arithmetic. Each member gets
`round(perFlex × flexes[i])` and the last takes the rounding remainder, so frames tile exactly at
any width. Members keep `translatesAutoresizingMaskIntoConstraints == true` and only ever receive
frames.

That is deliberate, not a shortcut. Because layout is a pure function of the vector, the
resize feedback loop that makes constraint-driven splitters re-enter layout until AppKit gives up
cannot happen here.

A divider drag turns the pixel delta into a flex delta on the pair it sits between, clamped to a
minimum member size with the remainder cascading into successive neighbours. Every step
recomputes from the sizes captured at mouse-down, so there is no incremental drift. Double-click
equalises the axis.

## Licence

MIT.
