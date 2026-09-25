//
//  PaneTree.swift
//  PaneLayout
//
//  A split tree of leaves and axes: the structural mutations, with layout left to the axes.
//
//  Created by David Sherlock on 9/26/26.
//

import AppKit

/// A split tree whose `root` is a single leaf or an axis of leaves and axes, mounted in
/// `container`. Generic over the leaf so a host keeps its own type all the way through:
/// `panes` gives back leaves, not `NSView`s to be cast.
///
/// The algorithms are Zed's exactly, and each is load-bearing:
/// - a **same-axis** split INSERTS into that axis's members, so the tree stays N-ary and flat
///   rather than growing a spine of two-member axes;
/// - a **cross-axis** split WRAPS the one member in place, leaving the parent's members and
///   flexes untouched so the wrapper inherits the slot's fraction — the property whose absence
///   made an `NSSplitView` attempt collapse to zero width;
/// - any membership change resets that axis's flexes to equal;
/// - an axis left with ONE member pops it into the parent slot, or becomes the root, splicing a
///   same-orientation axis flat so one run of dividers keeps ruling it.
///
/// There is no `NSSplitView` and no Auto Layout on members anywhere beneath this: an axis
/// assigns frames arithmetically from its flex vector, so the resize feedback loop that crashes
/// constraint-driven splitters is impossible by construction.
@MainActor public final class PaneTree<Leaf: NSView> {
    /// The view the tree is mounted in. A host sizes and places this.
    public let container = NSView()
    /// A `Leaf` or a `PaneAxisView`; nil when the tree is empty.
    public private(set) var root: NSView?
    /// Fallback split and focus target when nothing in the tree holds first responder.
    public weak var lastFocused: Leaf?
    /// Asks the host whether a leaf is empty, for the debug invariant check. A tree mid-split
    /// legitimately holds one empty leaf, which is why the check takes a flag rather than
    /// assuming.
    public var isLeafEmpty: ((Leaf) -> Bool)?

    private let makeLeaf: () -> Leaf

    /// - Parameter makeLeaf: Builds a new, unseeded leaf. Called by `createRootLeaf` and `split`.
    public init(makeLeaf: @escaping () -> Leaf) {
        self.makeLeaf = makeLeaf
    }

    /// Every leaf, depth-first — the tree's flat traversal order.
    public var panes: [Leaf] {
        var out: [Leaf] = []
        func walk(_ v: NSView?) {
            if let p = v as? Leaf { out.append(p) }
            else if let a = v as? PaneAxisView { a.members.forEach(walk) }
        }
        walk(root)
        return out
    }

    private func contains(_ pane: Leaf) -> Bool { panes.contains { $0 === pane } }

    /// The leaf in the tree's top-right corner — the one place a host can put chrome that
    /// belongs to the WHOLE tree rather than to a pane.
    ///
    /// The corner rather than the focused leaf, because the focused one moves as you click and a
    /// control you have to hunt for is worse than one you never use. With a single leaf nothing
    /// is different.
    public func cornerPane(in container: NSView) -> Leaf? {
        let all = panes
        guard let i = Self.cornerIndex(of: all.map { $0.convert($0.bounds, to: container) }) else { return nil }
        return all[i]
    }

    /// Index of the rect whose top-right corner is highest, then rightmost, in non-flipped
    /// AppKit coordinates. The pure half of `cornerPane(in:)`.
    public static func cornerIndex(of rects: [NSRect]) -> Int? {
        rects.indices.max { a, b in
            let ra = rects[a], rb = rects[b]
            if ra.maxY != rb.maxY { return ra.maxY < rb.maxY }
            return ra.maxX < rb.maxX
        }
    }

    /// The leaf a split, close or send targets: whichever holds first responder, else the last
    /// focused one, else the first.
    public func focusedPane(in window: NSWindow?) -> Leaf? {
        if let fr = window?.firstResponder as? NSView,
           let p = panes.first(where: { fr === $0 || fr.isDescendant(of: $0) }) {
            lastFocused = p
            return p
        }
        if let lf = lastFocused, contains(lf) { return lf }
        return panes.first
    }

    // MARK: - Mutations

    /// Seeds the tree with a single root leaf.
    @discardableResult
    public func createRootLeaf() -> Leaf {
        let p = makeLeaf()
        setRoot(p)
        lastFocused = p
        return p
    }

    /// Installs an already-built subtree as the root, for a restored layout.
    public func adopt(root newRoot: NSView) {
        setRoot(newRoot)
        lastFocused = panes.first
        assertTreeInvariants(allowEmptyLeaves: true)
    }

    /// Splits `pane`, inserting a new leaf. Returns it so the caller can lay out synchronously
    /// and then fill it.
    public func split(_ pane: Leaf, _ direction: PaneSplitDirection) -> Leaf? {
        guard contains(pane) else { return nil }
        let orientation = direction.orientation
        let newPane = makeLeaf()
        if let axis = pane.superview as? PaneAxisView {
            if axis.orientation == orientation {
                let idx = axis.members.firstIndex { $0 === pane } ?? axis.members.count
                axis.insertMember(newPane, at: direction.placesNewFirst ? idx : idx + 1)
            } else {
                let wrapper = PaneAxisView(orientation: orientation)
                axis.replaceMember(pane, with: wrapper)
                wrapper.setMembers(direction.placesNewFirst ? [newPane, pane] : [pane, newPane])
            }
        } else {
            let axis = PaneAxisView(orientation: orientation)
            setRoot(axis)
            axis.setMembers(direction.placesNewFirst ? [newPane, pane] : [pane, newPane])
        }
        lastFocused = newPane
        assertTreeInvariants(allowEmptyLeaves: true)   // the new leaf is filled right after
        return newPane
    }

    /// Removes a leaf, collapsing the tree around it.
    ///
    /// A still-surviving `lastFocused` is PRESERVED: removing an unfocused leaf, because its
    /// contents finished on their own in the background, must not move the focus target. Only
    /// when the removed leaf WAS the target does focus fall back, to that leaf's nearest
    /// sibling, and to nil when the tree emptied.
    public func remove(_ pane: Leaf) {
        guard contains(pane) else { return }
        if root === pane {
            setRoot(nil)
            lastFocused = nil
            return
        }
        guard let axis = pane.superview as? PaneAxisView else { return }
        // Resolve the neighbour BEFORE the tree mutates under it: previous member, else next.
        let idx = axis.members.firstIndex { $0 === pane }
        let sibling = idx.flatMap { i -> NSView? in
            i > 0 ? axis.members[i - 1] : (axis.members.count > i + 1 ? axis.members[i + 1] : nil)
        }
        axis.removeMember(pane)
        if axis.members.count == 1 { collapse(axis) }
        if lastFocused == nil || lastFocused === pane || !contains(lastFocused!) {
            lastFocused = firstLeaf(in: sibling) ?? panes.last
        }
        assertTreeInvariants(allowEmptyLeaves: false)
    }

    /// The first leaf, in traversal order, inside a subtree.
    private func firstLeaf(in v: NSView?) -> Leaf? {
        if let p = v as? Leaf { return p }
        if let a = v as? PaneAxisView {
            for m in a.members { if let p = firstLeaf(in: m) { return p } }
        }
        return nil
    }

    /// An axis left with ONE member pops it into the parent slot, keeping that slot's fraction,
    /// or becomes the root. A popped axis matching the parent's orientation is spliced flat so
    /// one set of dividers keeps ruling the run.
    private func collapse(_ axis: PaneAxisView) {
        guard axis.members.count == 1 else { return }
        let only = axis.takeMembers()[0]
        if let parent = axis.superview as? PaneAxisView {
            if let child = only as? PaneAxisView, child.orientation == parent.orientation {
                let idx = parent.members.firstIndex { $0 === axis } ?? parent.members.count
                parent.removeMember(axis)
                for (offset, g) in child.takeMembers().enumerated() {
                    parent.insertMember(g, at: idx + offset)
                }
            } else {
                parent.replaceMember(axis, with: only)
            }
        } else {
            axis.removeFromSuperview()
            setRoot(only)
        }
    }

    private func setRoot(_ v: NSView?) {
        root?.removeFromSuperview()
        root = v
        guard let v else { return }
        v.removeFromSuperview()          // may be re-parenting out of a collapsed axis
        v.autoresizingMask = [.width, .height]
        v.frame = container.bounds
        container.addSubview(v)
    }

    /// Debug-asserted after every mutation: matching counts, flex sums, no one-member axis, and
    /// no empty leaf except mid-split.
    public func assertTreeInvariants(allowEmptyLeaves: Bool) {
        #if DEBUG
        func walk(_ v: NSView) {
            if let a = v as? PaneAxisView {
                assert(a.members.count >= 2, "PaneTree: axis with fewer than 2 members")
                a.assertInvariants()
                a.members.forEach(walk)
            } else if let p = v as? Leaf, let isEmpty = isLeafEmpty {
                assert(allowEmptyLeaves || !isEmpty(p), "PaneTree: empty leaf in tree")
            }
        }
        if let root { walk(root) }
        #endif
    }
}
