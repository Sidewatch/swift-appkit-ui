//
//  FlowView.swift
//  AppKitViews
//
//  A view whose subviews flow left to right and wrap.
//
//  Created by David Sherlock on 9/28/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A view whose subviews flow left to right and wrap, each at its intrinsic size (``FlowLayout``).
/// It lays its subviews by frame; its host sizes it, asking ``contentHeight(forWidth:)`` — a
/// height that changes only when the number of lines does, so a host can follow it without the
/// width-to-height feedback loop a continuously reflowing view causes.
open class FlowView: NSView {
    /// The gap between two items on a line.
    public var spacing: CGFloat = 6 { didSet { needsLayout = true } }
    /// The gap between two lines.
    public var lineSpacing: CGFloat = 6 { didSet { needsLayout = true } }

    open override var isFlipped: Bool { true }

    /// Replaces the subviews with `views`, in order.
    public func setArrangedViews(_ views: [NSView]) {
        subviews.forEach { $0.removeFromSuperview() }
        for view in views {
            // Placed by frame, and narrowed when wider than a line: an item may not insist on its
            // full width, or the narrowed frame contradicts its own content-size constraint.
            view.translatesAutoresizingMaskIntoConstraints = true
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            addSubview(view)
        }
        needsLayout = true
    }

    /// The height the subviews take at `width`.
    public func contentHeight(forWidth width: CGFloat) -> CGFloat {
        FlowLayout.frames(for: itemSizes, width: width, spacing: spacing, lineSpacing: lineSpacing).height
    }

    open override func layout() {
        super.layout()
        let placed = FlowLayout.frames(for: itemSizes, width: bounds.width, spacing: spacing, lineSpacing: lineSpacing)
        for (view, frame) in zip(subviews, placed.frames) { view.frame = frame }
    }

    private var itemSizes: [CGSize] { subviews.map(\.intrinsicContentSize) }
}
