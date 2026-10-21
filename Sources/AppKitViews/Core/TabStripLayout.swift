//
//  TabStripLayout.swift
//  AppKitViews
//
//  Where the tabs of a horizontal strip sit, which one is under a point, and where a dragged one drops.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import CoreGraphics

/// The geometry of a horizontal strip of tabs laid edge to edge from x = 0, in content space (before
/// any scroll): each tab's origin, the tab under a point, where a dragged tab would land, and how far
/// to scroll to show one.
public struct TabStripLayout: Equatable, Sendable {
    /// Each tab's width, in strip order.
    public let widths: [CGFloat]

    /// A strip of tabs `widths` wide.
    public init(widths: [CGFloat]) { self.widths = widths }

    /// The strip's whole width.
    public var totalWidth: CGFloat { widths.reduce(0, +) }

    /// Where tab `index` starts: the widths before it (clamped to the strip).
    public func origin(of index: Int) -> CGFloat {
        widths.prefix(max(0, min(index, widths.count))).reduce(0, +)
    }

    /// The tab under content x `x`, or nil left of the strip or past its end.
    public func index(at x: CGFloat) -> Int? {
        guard x >= 0 else { return nil }
        var edge: CGFloat = 0
        for (i, w) in widths.enumerated() {
            edge += w
            if x < edge { return i }
        }
        return nil
    }

    /// Where tab `moving`, dragged so its centre is at `center`, would be inserted among the others (an
    /// index into the strip with it removed): after every other tab whose midpoint the centre has passed.
    public func insertionIndex(forCenter center: CGFloat, moving: Int) -> Int {
        var x: CGFloat = 0, insert = 0
        for (k, i) in widths.indices.filter({ $0 != moving }).enumerated() {
            if center > x + widths[i] / 2 { insert = k + 1 }
            x += widths[i]
        }
        return insert
    }

    /// Every tab's origin while tab `moving` is dragged to insertion index `target` with its own origin
    /// at `draggedOrigin`: the others close up around the slot it would take.
    public func origins(moving: Int, to target: Int, draggedOrigin: CGFloat) -> [CGFloat] {
        guard widths.indices.contains(moving) else { return origins }
        var order = Array(widths.indices)
        order.remove(at: moving)
        order.insert(moving, at: max(0, min(target, order.count)))
        var result = [CGFloat](repeating: 0, count: widths.count)
        var x: CGFloat = 0
        for i in order {
            result[i] = x
            x += widths[i]
        }
        result[moving] = draggedOrigin
        return result
    }

    /// Every tab's origin at rest.
    public var origins: [CGFloat] {
        var x: CGFloat = 0
        return widths.map { w in
            defer { x += w }
            return x
        }
    }

    /// The scroll offset that shows all of tab `index` in a window `visibleWidth` wide, moving `current`
    /// as little as possible, kept between 0 and the furthest the strip (plus `trailing`, room after the
    /// last tab such as an add button) can scroll. `current` itself (clamped) for an index out of range.
    public func scrollOffset(revealing index: Int, from current: CGFloat, visibleWidth: CGFloat, trailing: CGFloat = 0) -> CGFloat {
        let maxScroll = max(0, totalWidth + trailing - visibleWidth)
        var offset = current
        if widths.indices.contains(index) {
            let left = origin(of: index), right = left + widths[index]
            if left < offset {
                offset = left
            } else if right > offset + visibleWidth {
                offset = right - visibleWidth
            }
        }
        return min(max(0, offset), maxScroll)
    }
}
