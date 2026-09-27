//
//  NSColor+Hex.swift
//  AppKitViews
//
//  Colours from and to hex strings and CSS.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSColor {
    /// An sRGB colour from `#RGB`, `#RRGGBB` or `#RRGGBBAA` (the `#` and surrounding whitespace
    /// optional); nil for anything else.
    convenience init?(hex: String) {
        var s = Substring(hex.trimmingCharacters(in: .whitespacesAndNewlines))
        if s.hasPrefix("#") { s = s.dropFirst() }
        // Every character must be a hex digit: `UInt64(_:radix:)` accepts a leading sign, so
        // `#+12345` would otherwise decode as a colour.
        guard s.allSatisfy({ $0.isASCII && $0.isHexDigit }) else { return nil }
        if s.count == 3 { s = Substring(s.map { "\($0)\($0)" }.joined()) }
        guard s.count == 6 || s.count == 8, let v = UInt64(s, radix: 16) else { return nil }
        let rgb = s.count == 8 ? v >> 8 : v
        let alpha = s.count == 8 ? CGFloat(v & 0xFF) / 255 : 1
        self.init(
            srgbRed: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255, alpha: alpha)
    }

    /// The colour as `#RRGGBB` in sRGB, alpha dropped — a colour in any space converts the same way.
    var hexString: String {
        let (r, g, b) = srgbBytes
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    /// The colour for a style sheet: `#RRGGBB`, or `rgba(r, g, b, alpha)` when `alpha` is below 1.
    func cssColor(alpha: CGFloat = 1) -> String {
        guard alpha < 1 else { return hexString }
        let (r, g, b) = srgbBytes
        return "rgba(\(r), \(g), \(b), \(alpha))"
    }

    /// The red, green and blue components in sRGB, as bytes.
    private var srgbBytes: (Int, Int, Int) {
        let c = usingColorSpace(.sRGB) ?? self
        func byte(_ v: CGFloat) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return (byte(c.redComponent), byte(c.greenComponent), byte(c.blueComponent))
    }
}
