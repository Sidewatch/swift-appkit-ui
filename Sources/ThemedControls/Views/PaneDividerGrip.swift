//
//  PaneDividerGrip.swift
//  ThemedControls
//
//  A transparent, wide vertical strip drawn over the 1px editor↔preview divider that turns the
//  seam into a comfortable drag target (and shows the resize cursor).
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A transparent, wide vertical strip drawn over the 1px editor↔preview divider that turns
/// the seam into a comfortable drag target (and shows the resize cursor). It holds NO layout
/// state — it only reports the drag's X to `onDrag`; `EditorAreaView` owns the constraint
/// math — so there's nothing here that can desync from the panes it sits between.
public final class PaneDividerGrip: NSView {
    /// The drag's current X, in the SUPERVIEW's coordinate system.
    public var onDrag: ((CGFloat) -> Void)?

    /// Width of the strip. 14pt — seven either side of the 1px seam. A narrower target is
    /// live but hard to find, especially beside a table whose overlay scroller appears in the
    /// same place; Apple's thin split dividers claim a comparable slop.
    public static let width: CGFloat = 14

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // A tracking area, NOT just `resetCursorRects`: cursor rects are rebuilt only when the
        // window invalidates them, and a view that moves on every resize ends up with stale
        // ones, so the resize cursor never appears. `.cursorUpdate` is driven by the event
        // system and does not depend on that invalidation cycle.
        addTrackingArea(
            NSTrackingArea(
                rect: .zero,
                options: [.cursorUpdate, .activeInKeyWindow, .inVisibleRect],
                owner: self))
    }

    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

    public override func cursorUpdate(with event: NSEvent) { NSCursor.resizeLeftRight.set() }

    /// Kept as well as the tracking area: they cover different moments (cursor rects apply on
    /// entry from outside the window, the tracking area while moving within it), and together
    /// the cursor is correct in both.
    public override func resetCursorRects() { addCursorRect(bounds, cursor: .resizeLeftRight) }

    public override func mouseDown(with event: NSEvent) { /* accept, so the drag stream follows */  }
    public override func mouseDragged(with event: NSEvent) {
        guard let sup = superview else { return }
        onDrag?(sup.convert(event.locationInWindow, from: nil).x)
    }
}

// MARK: - Accessibility

extension PaneDividerGrip {
    public override func isAccessibilityElement() -> Bool { true }
    public override func accessibilityRole() -> NSAccessibility.Role? { .splitter }
    public override func accessibilityLabel() -> String? { String(localized: "Pane divider", bundle: .module) }
}
