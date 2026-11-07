//
//  HiddenPaneSplitView.swift
//  AppKitViews
//
//  A split view that leaves no divider beside a hidden pane.
//
//  Created by David Sherlock on 11/7/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A split view that leaves no divider beside a hidden pane.
///
/// NSSplitView collapses a hidden pane but keeps its divider: a thin divider is a layer of its own,
/// moved only when the split view lays out, so after `adjustSubviews()` it stays where the pane's
/// edge was, a line across the pane that took the room. Once laid out it sits at the far edge, or
/// at the near edge, inside the visible pane, when the hidden pane is the first. This one gives
/// the divider no thickness while any pane is hidden and lays itself out after every adjustment.
open class HiddenPaneSplitView: NSSplitView {
    open override var dividerThickness: CGFloat {
        subviews.contains(where: \.isHidden) ? 0 : super.dividerThickness
    }

    open override func adjustSubviews() {
        super.adjustSubviews()
        needsLayout = true
    }
}
