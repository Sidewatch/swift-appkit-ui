//
//  PaneAxisView.swift
//  PaneLayout
//
//  One axis node of a split tree: lays out its members — leaves or nested axes — along one
//  axis from a **flex vector**,
//  the ONLY size truth (invariants: `flexes.count == members.count`, sum ==…
//
//  Created by David Sherlock on 9/26/26.
//

import AppKit
import ThemedControls

/// One axis node of a split tree: lays out
/// its members — leaves or nested axes — along one axis from a
/// **flex vector**, the ONLY size truth (invariants: `flexes.count == members.count`,
/// sum == count). `layout()` assigns frames arithmetically: `perFlex = length / count`,
/// member i gets `round(perFlex × flexes[i])` and the LAST member takes the rounding
/// remainder so frames tile exactly. NO NSSplitView, NO Auto Layout on members (they
/// keep `translatesAutoresizingMaskIntoConstraints == true` and only ever receive
/// frames) — layout is a pure function of the vector, so the resize-loop crash class
/// the first split attempt died on is impossible by construction.
public final class PaneAxisView: NSView {
    /// Which way this axis lays its members out.
    public let orientation: PaneOrientation
    /// The views this axis lays out, in order: leaves or nested axes.
    public private(set) var members: [NSView] = []
    /// The size vector, the ONLY size truth. `flexes.count == members.count`, and they sum to `members.count`.
    public private(set) var flexes: [CGFloat] = []
    private var dividers: [PaneDividerView] = []

    /// A divider drag never shrinks a member below this (a small window still scales
    /// everything down proportionally — layout only scales, it never fights).
    private var minMemberLength: CGFloat { orientation == .horizontal ? 80 : 100 }

    public init(orientation: PaneOrientation) {
        self.orientation = orientation
        super.init(frame: .zero)
    }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

    /// Offsets run top-left → bottom-right on both axes.
    public override var isFlipped: Bool { true }

    public override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        needsLayout = true
    }

    // MARK: - Membership (every mutation is array work + `needsLayout` — nothing re-enters)

    /// Seeds the axis with `views` at equal flexes (used when the axis is created).
    public func setMembers(_ views: [NSView]) {
        members.forEach { $0.removeFromSuperview() }
        members = views
        for v in views {
            v.autoresizingMask = []
            addSubview(v)
        }
        resetFlexesEqual()
        rebuildDividers()
        needsLayout = true
        assertInvariants()
    }

    /// Same-axis split: INSERT into the members (flatten-on-insert, N-ary). Any
    /// membership change resets this axis's flexes to all-equal.
    public func insertMember(_ view: NSView, at index: Int) {
        let idx = min(max(index, 0), members.count)
        view.autoresizingMask = []
        addSubview(view)
        members.insert(view, at: idx)
        resetFlexesEqual()
        rebuildDividers()
        needsLayout = true
        assertInvariants()
    }

    public func removeMember(_ view: NSView) {
        guard let idx = members.firstIndex(where: { $0 === view }) else { return }
        members.remove(at: idx)
        view.removeFromSuperview()
        resetFlexesEqual()
        rebuildDividers()
        needsLayout = true
        assertInvariants()
    }

    /// Cross-axis split / collapse plumbing: swaps `old` for `new` IN PLACE. The slot's
    /// flex is untouched, so the replacement inherits the slot's fraction — precisely
    /// the property whose absence made the reverted NSSplitView attempt go 0-wide.
    public func replaceMember(_ old: NSView, with new: NSView) {
        guard let idx = members.firstIndex(where: { $0 === old }) else { return }
        old.removeFromSuperview()
        new.autoresizingMask = []
        addSubview(new)
        members[idx] = new
        rebuildDividers()
        needsLayout = true
        assertInvariants()
    }

    /// Detaches and returns every member (collapse plumbing — the axis is discarded after).
    public func takeMembers() -> [NSView] {
        let out = members
        members.forEach { $0.removeFromSuperview() }
        members = []
        flexes = []
        rebuildDividers()
        return out
    }

    /// Restores a persisted flex vector (already validated by the caller).
    public func setFlexes(_ f: [CGFloat]) {
        guard f.count == members.count else { return }
        flexes = f
        needsLayout = true
        assertInvariants()
    }

    /// Double-click a divider: every member back to an equal share.
    public func equalize() {
        resetFlexesEqual()
        needsLayout = true
    }

    private func resetFlexesEqual() {
        flexes = Array(repeating: 1, count: members.count)
    }

    private func rebuildDividers() {
        dividers.forEach { $0.removeFromSuperview() }
        dividers = (0..<max(0, members.count - 1)).map { i in
            let d = PaneDividerView(axis: self, index: i)
            // Added after the members so the hairline + hit strip stay on top.
            addSubview(d)
            return d
        }
    }

    public func assertInvariants() {
        assert(flexes.count == members.count, "PaneAxisView: flex/member count mismatch")
        assert(members.isEmpty || abs(flexes.reduce(0, +) - CGFloat(members.count)) < 0.01,
               "PaneAxisView: flex sum drifted from member count")
    }

    // MARK: - Layout (pure arithmetic — cannot loop)

    public override func layout() {
        super.layout()
        guard !members.isEmpty else { return }
        let horizontal = orientation == .horizontal
        let total = horizontal ? bounds.width : bounds.height
        let cross = max(0, horizontal ? bounds.height : bounds.width)
        let perFlex = total / CGFloat(members.count)
        var offset: CGFloat = 0
        for (i, m) in members.enumerated() {
            let len = (i == members.count - 1)
                ? max(0, total - offset)                       // last member takes the remainder
                : max(0, (perFlex * flexes[i]).rounded())
            m.frame = horizontal
                ? NSRect(x: offset, y: 0, width: len, height: cross)
                : NSRect(x: 0, y: offset, width: cross, height: len)
            offset += len
        }
        for (i, d) in dividers.enumerated() {
            let edge = horizontal ? members[i].frame.maxX : members[i].frame.maxY
            d.frame = horizontal
                ? NSRect(x: edge - 2.5, y: 0, width: 5, height: bounds.height)
                : NSRect(x: 0, y: edge - 2.5, width: bounds.width, height: 5)
            window?.invalidateCursorRects(for: d)
        }
    }

    // MARK: - Divider drag

    /// Tracks a divider drag: the pixel delta becomes a flex delta on the (index,
    /// index+1) pair, clamped to the minimum member size with the remainder cascading
    /// into successive neighbors (Zed's resize). Each step recomputes `flexes` from the
    /// sizes captured at mouse-down (no incremental drift) and marks THIS axis for
    /// layout only.
    public func beginDividerDrag(at index: Int, with event: NSEvent) {
        guard members.indices.contains(index + 1), let window else { return }
        let horizontal = orientation == .horizontal
        let start = convert(event.locationInWindow, from: nil)
        let startSizes = members.map { horizontal ? $0.frame.width : $0.frame.height }
        while true {
            guard let e = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) else { break }
            if e.type == .leftMouseUp { break }
            let p = convert(e.locationInWindow, from: nil)
            applyDrag(at: index, delta: horizontal ? p.x - start.x : p.y - start.y, from: startSizes)
            layoutSubtreeIfNeeded()   // live feedback; pure arithmetic, safe synchronously
        }
    }

    private func applyDrag(at i: Int, delta: CGFloat, from startSizes: [CGFloat]) {
        var sizes = startSizes
        let minLen = minMemberLength
        if delta > 0 {
            // Boundary moves toward later members: shrink i+1, i+2, … (each to its
            // minimum), grow member i by what was actually taken.
            var want = delta, taken: CGFloat = 0
            var j = i + 1
            while j < sizes.count, want > 0.5 {
                let give = min(want, max(0, sizes[j] - minLen))
                sizes[j] -= give; taken += give; want -= give; j += 1
            }
            sizes[i] += taken
        } else if delta < 0 {
            var want = -delta, taken: CGFloat = 0
            var j = i
            while j >= 0, want > 0.5 {
                let give = min(want, max(0, sizes[j] - minLen))
                sizes[j] -= give; taken += give; want -= give; j -= 1
            }
            sizes[i + 1] += taken
        }
        let total = sizes.reduce(0, +)
        guard total > 0 else { return }
        flexes = sizes.map { $0 / total * CGFloat(sizes.count) }
        needsLayout = true
        assertInvariants()
    }
}
