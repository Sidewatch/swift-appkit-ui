//
//  NSScrollView+Zoom.swift
//  AppKitViews
//
//  The zoom keys on a magnifying scroll view.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSScrollView {
    /// One ⌘= / ⌘- step (``ZoomStep``) within the scroll view's magnification range, kept centred on what
    /// the viewport shows. ``ZoomKeyDirection/actual`` does nothing here; call ``fitMagnification(to:allowEnlarge:)``.
    func stepMagnification(_ direction: ZoomKeyDirection) {
        guard let scale = ZoomStep.next(magnification, direction, in: minMagnification...maxMagnification) else { return }
        let clip = contentView.bounds
        setMagnification(scale, centeredAt: NSPoint(x: clip.midX, y: clip.midY))
    }

    /// Magnifies so `content` (the document's size at 1×) fits the viewport, measured from the FRAME as the
    /// area left when this scroll view's scrollers show (``fittingContentSize``) — never from the clip view's
    /// bounds, which are in document coordinates and shrink as magnification grows (fitting by them gave a
    /// scale that changed with every press). Fitting inside the area the scrollers leave means the content
    /// fits whichever state they are in, so legacy scrollers hide; fitted to the whole frame, an image just
    /// too tall for the scrollers-shown area keeps both scrollers up, each one forcing the other.
    func fitMagnification(to content: CGSize, allowEnlarge: Bool) {
        guard let scale = ZoomStep.fitScale(content: content, viewport: fittingContentSize, allowEnlarge: allowEnlarge) else { return }
        magnification = scale
    }

    /// The content area this scroll view's frame leaves with its scrollers showing (legacy scrollers take
    /// space, overlay ones none), whatever they show now.
    var fittingContentSize: CGSize {
        NSScrollView.contentSize(
            forFrameSize: frame.size, horizontalScrollerClass: hasHorizontalScroller ? NSScroller.self : nil,
            verticalScrollerClass: hasVerticalScroller ? NSScroller.self : nil, borderType: borderType, controlSize: .regular,
            scrollerStyle: scrollerStyle)
    }
}
