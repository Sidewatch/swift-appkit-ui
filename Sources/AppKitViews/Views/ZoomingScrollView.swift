//
//  ZoomingScrollView.swift
//  AppKitViews
//
//  A scroll view whose mouse wheel zooms instead of scrolls, anchored at the pointer.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A scroll view whose mouse wheel zooms instead of scrolls: precise trackpad deltas scale
/// smoothly per pixel, wheel detents step by a fixed factor. The zoom is anchored at the
/// POINTER — zooming to the view's centre while inspecting a corner is the thing to avoid.
///
/// Scroll is free to mean zoom because panning is a drag (see `PannableImageView`), which is
/// what people reach for on an image. An earlier version zoomed only a DETENTED wheel and
/// passed precise deltas straight to `super`, so on a trackpad or a Magic Mouse scroll just
/// scrolled and nothing zoomed but pinch. Precise deltas are pixel-scale and continuous, a
/// wheel's are line-scale and chunky, so each is scaled to a factor that feels the same in the
/// hand; a positive delta zooms in.
///
/// Set `minMagnification` and `maxMagnification` as usual; `allowsMagnification` governs
/// PROGRAMMATIC magnification too, and with it false a `magnification` assignment is silently
/// ignored — so a host that means to fit its content by magnifying must turn it on.
public final class ZoomingScrollView: NSScrollView {
    /// Zoom step per wheel detent. Multiplicative, so each detent moves the same visual
    /// proportion at any magnification.
    private static let zoomPerDetent: CGFloat = 1.12
    /// How many detents one event may be worth, so a flicked wheel cannot jump the whole range.
    private static let detentLimit: CGFloat = 3

    public override func scrollWheel(with event: NSEvent) {
        let deltaY = event.scrollingDeltaY
        guard deltaY != 0 else { super.scrollWheel(with: event); return }
        let factor: CGFloat
        if event.hasPreciseScrollingDeltas {
            factor = pow(1.0015, deltaY)                                    // smooth, per-pixel
        } else {
            let steps = min(max(deltaY, -Self.detentLimit), Self.detentLimit)
            factor = pow(Self.zoomPerDetent, steps)                         // chunky wheel
        }
        let wanted = magnification * factor
        let clamped = min(max(wanted, minMagnification), maxMagnification)
        guard clamped != magnification else { return }
        // `centeredAt` wants the anchor in the clip view's coordinate system, which is the
        // document's — so the point under the cursor stays under the cursor.
        setMagnification(clamped, centeredAt: contentView.convert(event.locationInWindow, from: nil))
    }
}
