//
//  NSColor+Blend.swift
//  AppKitViews
//
//  Blending one colour toward another.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSColor {
    /// This colour, in sRGB, blended `fraction` of the way toward `other` — how a surface is
    /// lifted off a background. Falls back to `self` when the blend cannot be computed.
    func blended(_ fraction: CGFloat, toward other: NSColor) -> NSColor {
        let a = usingColorSpace(.sRGB) ?? self
        let b = other.usingColorSpace(.sRGB) ?? other
        return a.blended(withFraction: fraction, of: b) ?? self
    }
}
