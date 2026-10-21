//
//  ZoomStep.swift
//  AppKitViews
//
//  The zoom keys' arithmetic: one step in or out, and the scale that fits content to a viewport.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import CoreGraphics

/// The zoom keys' arithmetic, kept apart from any view: ⌘= / ⌘- multiply or divide by ``factor`` within
/// a range, and ⌘0 returns to the scale that fits the content in the viewport.
public enum ZoomStep {
    /// One zoom step: ×1.25 in, ÷1.25 out.
    public static let factor: CGFloat = 1.25

    /// The scale one step from `current` in `direction`, clamped to `range`; nil for ``ZoomKeyDirection/actual``
    /// (the caller fits instead).
    public static func next(_ current: CGFloat, _ direction: ZoomKeyDirection, in range: ClosedRange<CGFloat>) -> CGFloat? {
        switch direction {
        case .in: min(current * factor, range.upperBound)
        case .out: max(current / factor, range.lowerBound)
        case .actual: nil
        }
    }

    /// The scale at which `content` fits whole inside `viewport` — capped at 1 unless `allowEnlarge`, so
    /// a small image is not blown up. Nil when either size is empty.
    public static func fitScale(content: CGSize, viewport: CGSize, allowEnlarge: Bool) -> CGFloat? {
        guard content.width > 0, content.height > 0, viewport.width > 0, viewport.height > 0 else { return nil }
        let fit = min(viewport.width / content.width, viewport.height / content.height)
        return allowEnlarge ? fit : min(fit, 1)
    }
}
