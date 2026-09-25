//
//  CenteringClipView.swift
//  AppKitViews
//
//  A clip view that keeps the document centred while it is smaller than the viewport.
//
//  Created by David Sherlock on 9/26/26.
//

import AppKit

/// A clip view that keeps the document centred while it is smaller than the viewport, so a
/// small image sits in the middle of its scroll view rather than in the bottom-left corner.
public final class CenteringClipView: NSClipView {
    /// Overrides the default top-left origin: on whichever axis the viewport is bigger than the
    /// document, the origin is offset so the document sits centred on that axis.
    public override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        guard let doc = documentView else { return rect }
        if rect.width > doc.frame.width {
            rect.origin.x = (doc.frame.width - rect.width) / 2
        }
        if rect.height > doc.frame.height {
            rect.origin.y = (doc.frame.height - rect.height) / 2
        }
        return rect
    }
}
