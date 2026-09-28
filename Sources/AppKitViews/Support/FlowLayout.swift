//
//  FlowLayout.swift
//  AppKitViews
//
//  Items laid left to right, wrapping onto a new line when the width runs out.
//
//  Created by David Sherlock on 9/28/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import CoreGraphics

/// Items laid left to right, wrapping onto a new line when the width runs out — the geometry of a
/// strip of tags or pills, as a pure function so it can be tested without a view.
public enum FlowLayout {
    /// Where each item goes, in a flipped (top-down) space, and the height the lines take.
    ///
    /// An item wider than `width` is narrowed to it. A line is as tall as its tallest item, and
    /// items sit at the top of their line.
    ///
    /// - Parameters:
    ///   - sizes: Each item's preferred size, in order.
    ///   - width: The width to fill.
    ///   - spacing: The gap between two items on a line.
    ///   - lineSpacing: The gap between two lines.
    public static func frames(for sizes: [CGSize], width: CGFloat, spacing: CGFloat, lineSpacing: CGFloat) -> (
        frames: [CGRect], height: CGFloat
    ) {
        var frames: [CGRect] = []
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0
        for size in sizes {
            let w = min(size.width, max(width, 0))
            if x > 0 && x + w > width {
                y += lineHeight + lineSpacing
                x = 0
                lineHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: w, height: size.height))
            x += w + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return (frames, sizes.isEmpty ? 0 : y + lineHeight)
    }
}
