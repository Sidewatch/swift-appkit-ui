//
//  NSTextView+ScrollHosting.swift
//  AppKitViews
//
//  The settings a text view needs to live in a vertically scrolling scroll view.
//
//  Created by David Sherlock on 10/20/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

extension NSTextView {
    /// Makes this text view grow downward inside a scroll view and wrap at the scroll view's
    /// width: no minimum size, an unbounded maximum, vertically resizable only, the width
    /// following its superview (`.width` autoresizing) and the container tracking the view.
    ///
    /// A text view made with `init()` or `init(frame:textContainer:)` gets none of this, and
    /// without it the text lays out invisibly or the view never scrolls. Call it before
    /// assigning the view as a scroll view's `documentView`.
    public func configureForVerticalScrolling() {
        minSize = .zero
        maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        isVerticallyResizable = true
        isHorizontallyResizable = false
        autoresizingMask = [.width]
        textContainer?.widthTracksTextView = true
        textContainer?.containerSize = NSSize(width: frame.width, height: CGFloat.greatestFiniteMagnitude)
    }
}
