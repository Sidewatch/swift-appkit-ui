//
//  EdgeDrag.swift
//  AppKitViews
//
//  A pane's size while its edge is dragged.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import CoreGraphics

/// One drag of a pane's edge: where it started, the pane's size then, which way it grows and the range
/// it may take. ``size(at:)`` is the pane's size with the pointer at a window location.
public struct EdgeDrag: Equatable, Sendable {
    /// Where the drag started, in window coordinates.
    public let start: CGPoint
    /// The pane's size when the drag started.
    public let startSize: CGFloat
    /// Which way the pane grows.
    public let grows: EdgeDragDirection
    /// The sizes the pane may take.
    public let range: ClosedRange<CGFloat>

    /// A drag from `start` of a pane `size` big that grows toward `grows`, kept within `range`.
    public init(from start: CGPoint, size: CGFloat, grows: EdgeDragDirection, range: ClosedRange<CGFloat>) {
        self.start = start
        self.startSize = size
        self.grows = grows
        self.range = range
    }

    /// The pane's size with the pointer at `location` (window coordinates): the start size plus how far
    /// the pointer has moved the way the pane grows, clamped to ``range``.
    public func size(at location: CGPoint) -> CGFloat {
        let moved: CGFloat
        switch grows {
        case .up: moved = location.y - start.y
        case .down: moved = start.y - location.y
        case .left: moved = start.x - location.x
        case .right: moved = location.x - start.x
        }
        return min(max(startSize + moved, range.lowerBound), range.upperBound)
    }
}
