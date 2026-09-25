//
//  NSOutlineView+Expansion.swift
//  AppKitViews
//
//  Opening and closing an outline whole, or as far as it stays readable, in one layout.
//
//  Created by David Sherlock on 9/26/26.
//

import AppKit

extension NSOutlineView {
    /// Opens every node of the outline, however deep.
    ///
    /// ONE call does it. The obvious worry is a lazily-built tree — that `expandChildren` would
    /// only walk what the data source had already been asked about — and it was written here as
    /// a sweep repeated until the row count settled. Tested (26 Sep 2026), that is not how it
    /// behaves: AppKit queries each newly opened node as it goes, so any source that answers its
    /// children when asked is fully reached in one pass, and a source that answers zero on the
    /// first ask is not opened by repeating either. The loop was defensive code for a case that
    /// does not exist, and no test could be written that it fixed.
    ///
    /// The batching is the part that matters, and it was MEASURED rather than assumed: a walk
    /// that collapses or expands row by row re-sets the row map per call, which is quadratic —
    /// 0.39 s to open and 0.71 s to close a 22,000-row document, a visible stall on a menu item,
    /// against 0.21 s and 0.24 s batched with the animations off.
    public func expandEveryNode() {
        withoutRowAnimation { expandItem(nil, expandChildren: true) }
    }

    /// Closes every node. ONE call with `collapseChildren: true` from the root does it; walking
    /// the rows deepest-first closes the same nodes for the quadratic cost described above.
    public func collapseEveryNode() {
        withoutRowAnimation { collapseItem(nil, collapseChildren: true) }
    }

    /// Opens the tree LEVEL BY LEVEL while the result still fits `rowLimit`, so a small document
    /// lands open and ready to read while a big one lands at whatever depth keeps it a map
    /// rather than a wall.
    ///
    /// Two rules worth keeping. The FIRST level always opens, however large, because a tree
    /// whose roots are closed says nothing at all. And a level opens whole or not at all, so the
    /// depth is even rather than depending on which branch the walk reached first.
    public func autoExpand(rowLimit: Int, maxDepth: Int = 32) {
        var level = 0
        while level < maxDepth {
            let closed = (0..<numberOfRows).compactMap { row -> Any? in
                guard self.level(forRow: row) == level, let item = item(atRow: row),
                      isExpandable(item), !isItemExpanded(item) else { return nil }
                return item
            }
            guard !closed.isEmpty else { return }
            let wouldAdd = closed.reduce(0) { $0 + numberOfChildren(ofItem: $1) }
            if level > 0, numberOfRows + wouldAdd > rowLimit { return }
            withoutRowAnimation { closed.forEach { expandItem($0) } }
            level += 1
        }
    }

    /// Runs `work` with the row animations off and the updates batched — an outline that opens
    /// or closes thousands of rows should cost one layout, not thousands of animated ones.
    private func withoutRowAnimation(_ work: () -> Void) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        beginUpdates()
        work()
        endUpdates()
        NSAnimationContext.endGrouping()
    }
}
