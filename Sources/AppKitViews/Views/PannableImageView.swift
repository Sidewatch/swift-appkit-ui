//
//  PannableImageView.swift
//  AppKitViews
//
//  An image view with hand-cursor drag-to-pan, for studying a zoomed image without scrollers.
//
//  Created by David Sherlock on 9/26/26.
//

import AppKit

/// An image view that pans under a drag, with the hand cursor, so a zoomed-in image can be
/// studied without reaching for a scroller.
///
/// The pan lives on the IMAGE VIEW rather than on the scroll view because `NSImageView` is an
/// `NSControl` and consumes `mouseDown` for cell tracking — an override at scroll-view level
/// would never see the drag. A host that covers this view with an overlay (a marquee, an
/// annotation layer) takes the drag away from it cleanly, since this view then gets no mouse
/// events at all.
public final class PannableImageView: NSImageView {
    /// The previous drag point in WINDOW coordinates — this view's own space moves and scales
    /// underneath the drag, so it cannot be the reference frame.
    private var panPoint: NSPoint?

    public override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }

    public override func mouseDown(with event: NSEvent) {
        guard enclosingScrollView != nil else { super.mouseDown(with: event); return }
        panPoint = event.locationInWindow
        NSCursor.closedHand.push()
    }

    /// Moves the clip view by the drag delta, converted from window points to document points:
    /// the clip's bounds shrink as magnification grows, so a 1 pt drag must move the origin
    /// 1/magnification document points to track the cursor. It scrolls through the CLIP VIEW,
    /// so a `CenteringClipView` still gets to constrain the result.
    public override func mouseDragged(with event: NSEvent) {
        guard let scroll = enclosingScrollView, let last = panPoint else {
            super.mouseDragged(with: event)
            return
        }
        let now = event.locationInWindow
        let scale = max(scroll.magnification, 0.0001)
        let clip = scroll.contentView
        var origin = clip.bounds.origin
        origin.x -= (now.x - last.x) / scale
        origin.y -= (now.y - last.y) / scale
        clip.scroll(to: origin)
        scroll.reflectScrolledClipView(clip)
        panPoint = now
    }

    public override func mouseUp(with event: NSEvent) {
        guard panPoint != nil else { super.mouseUp(with: event); return }
        panPoint = nil
        NSCursor.pop()   // balances the push in mouseDown
    }

    /// A drag interrupted by the view being torn down — switching tabs with the button still
    /// down — never receives its `mouseUp`, so the cursor stack is balanced here too. Without
    /// it the closed hand outlives the image it was grabbing.
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window == nil, panPoint != nil else { return }
        panPoint = nil
        NSCursor.pop()
    }
}
