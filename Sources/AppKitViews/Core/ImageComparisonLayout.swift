//
//  ImageComparisonLayout.swift
//  AppKitViews
//
//  Where an image comparison puts its pictures.
//
//  Created by David Sherlock on 10/22/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import CoreGraphics

/// Where ``ImageComparisonView`` puts its pictures, as pure geometry.
public enum ImageComparisonLayout {
    /// The most a small picture is enlarged to fill its space (a 16-pixel icon shows at 256).
    public static let maxScale: CGFloat = 16

    /// `size` scaled to fit inside `rect` with its shape kept, centred and on whole points;
    /// enlarged up to `maxScale`. Empty when either is empty.
    public static func fit(_ size: CGSize, in rect: CGRect, maxScale: CGFloat = maxScale) -> CGRect {
        guard size.width > 0, size.height > 0, rect.width > 0, rect.height > 0 else { return .zero }
        let scale = min(rect.width / size.width, rect.height / size.height, maxScale)
        let width = (size.width * scale).rounded(), height = (size.height * scale).rounded()
        return CGRect(x: (rect.midX - width / 2).rounded(), y: (rect.midY - height / 2).rounded(), width: width, height: height)
    }

    /// The two halves of `bounds` for side by side, `gap` apart.
    public static func panes(in bounds: CGRect, gap: CGFloat) -> (old: CGRect, new: CGRect) {
        let width = max(0, (bounds.width - gap) / 2)
        return (
            CGRect(x: bounds.minX, y: bounds.minY, width: width, height: bounds.height),
            CGRect(x: bounds.maxX - width, y: bounds.minY, width: width, height: bounds.height)
        )
    }

    /// The swipe divider's place, 0…1 across `frame`, for a pointer at `x`.
    public static func swipeFraction(atX x: CGFloat, in frame: CGRect) -> CGFloat {
        guard frame.width > 0 else { return 0.5 }
        return min(1, max(0, (x - frame.minX) / frame.width))
    }
}
