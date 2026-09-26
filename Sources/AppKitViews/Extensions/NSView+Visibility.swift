//
//  NSView+Visibility.swift
//  AppKitViews
//
//  Whether a person could see a view right now.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSView {
    /// True when the view is on screen for the person: in a visible window, neither it nor an
    /// ancestor hidden, and some of its area left after every clipping ancestor (a scroll view's
    /// clip view, any view that clips to its bounds) and the window's content area cut it.
    ///
    /// Computed here rather than read from `visibleRect`: with `clipsToBounds` off by default
    /// (macOS 14 and later) `visibleRect` does not shrink for a view scrolled out of sight.
    var isVisibleToUser: Bool {
        guard let window, window.isVisible, !isHiddenOrHasHiddenAncestor, !bounds.isEmpty else { return false }
        var rect = convert(bounds, to: nil)
        var ancestor = superview
        while let view = ancestor {
            if view is NSClipView || view.clipsToBounds { rect = rect.intersection(view.convert(view.bounds, to: nil)) }
            ancestor = view.superview
        }
        if let content = window.contentView { rect = rect.intersection(content.convert(content.bounds, to: nil)) }
        return !rect.isEmpty
    }
}
