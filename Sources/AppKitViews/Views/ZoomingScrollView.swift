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

/// A scroll view whose mouse wheel zooms, anchored at the pointer, instead of scrolling (panning
/// is a drag, see `PannableImageView`). Trackpad deltas scale smoothly per pixel and wheel
/// detents step by a fixed factor, each tuned to feel the same; a positive delta zooms in.
///
/// `allowsMagnification` governs programmatic magnification too: with it false, a
/// `magnification` assignment is silently ignored, so a host that fits by magnifying must set it.
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
