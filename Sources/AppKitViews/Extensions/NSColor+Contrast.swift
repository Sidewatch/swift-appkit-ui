//
//  NSColor+Contrast.swift
//  AppKitViews
//
//  How far apart two colours read: WCAG relative luminance and contrast ratio.
//
//  Created by David Sherlock on 10/13/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSColor {
    /// WCAG 2 relative luminance, 0 (black) to 1 (white), of this colour in sRGB. Alpha is
    /// ignored. Nil when the colour has no sRGB form (a pattern colour).
    var relativeLuminance: CGFloat? {
        guard let c = usingColorSpace(.sRGB) else { return nil }
        func linear(_ v: CGFloat) -> CGFloat { v <= 0.040_45 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(c.redComponent) + 0.7152 * linear(c.greenComponent) + 0.0722 * linear(c.blueComponent)
    }

    /// WCAG 2 contrast ratio against `other`: 1 (the same luminance) to 21 (black on white).
    /// 1 when either colour has no sRGB form.
    func contrastRatio(with other: NSColor) -> CGFloat {
        guard let a = relativeLuminance, let b = other.relativeLuminance else { return 1 }
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}
