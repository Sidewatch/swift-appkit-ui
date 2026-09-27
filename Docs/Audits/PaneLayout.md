# Audit trail

## Extraction and first audit — 26 September 2026

Extracted from Sidewatch's terminal panel, where it had been `TerminalPaneTree`, `PaneAxisView`,
`PaneDividerView` and `TerminalSplitDirection`. The algorithms are unchanged; what changed is the
coupling.

### Done in the move

- **`PaneTree` is generic over its leaf.** The app's version named `TerminalPaneView` throughout,
  so `panes` gave terminals and nothing else could use it. `PaneTree<Leaf: NSView>` gives the
  host's own type back.
- **The leaf-emptiness check became a closure.** The tree asserted `!p.terminals.isEmpty`, which
  only a terminal pane can answer. `isLeafEmpty` is optional, so a host that does not care simply
  does not set it.
- **`PaneDividerView` reads `ThemedControls.palette.border`** and observes
  `ThemedControls.paletteDidChange`, rather than the app's `Theme` and `.themeDidChange`.
- **`PaneSplitDirection` replaced `TerminalSplitDirection`**, with `orientation` in place of
  `isHorizontalAxis` so the caller never reasons about which axis a direction implies.
- The app's `clamped(low:high:)` extension was inlined as `min(max(...))`, so the package needs no
  helper of its own.

### Mutation verification

31 tests. Six mutants, each confirmed:

| mutant | caught by |
|---|---|
| same-axis split nests instead of inserting | 3 tests |
| cross-axis split removes and re-inserts, losing the slot's flex | `testACrossAxisSplitWrapsInPlaceAndLeavesTheParentAlone` |
| no collapse, a one-member axis survives | **SIGTRAP from `assertTreeInvariants`** |
| focus always falls back to the first pane | `testRemovingAnUnfocusedLeafLeavesTheFocusTargetAlone` |
| `replaceMember` resets the flexes | `testReplacingAMemberKeepsTheSlotsFraction` |
| the last member does not take the remainder | `testAnAwkwardWidthStillTilesExactly` |

**The cross-axis test failed to catch its mutant on the first attempt**, because it set up three
members at EQUAL flexes. Remove-and-reinsert resets to equal, and replace-in-place preserves
equal, so the two are indistinguishable. It sets `[1.5, 1.0, 0.5]` now. Any test of "this
operation preserves the vector" needs an uneven vector or it cannot fail.

**The collapse mutant traps rather than failing.** `assertTreeInvariants` asserts every axis has
at least two members, and that fires during `remove` before any assertion is reached, so the run
dies with signal 5. The protection is real; the diagnostic is just blunt. A signal 5 here means an
invariant fired.

## Known non-issues

- `PaneAxisView.beginDividerDrag` runs a `nextEvent(matching:)` tracking loop, which no headless
  test can drive. The pure half, `applyDrag`, is exercised through `setFlexes` and the layout
  tests; the drag itself is checked in Sidewatch's own harness against a real window.
- `members` is `public private(set)` with mutation through the named methods. That is deliberate:
  a direct write would desynchronise the flex vector, which is the one invariant everything rests
  on.
