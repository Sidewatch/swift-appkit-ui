//
//  NSImage+Symbol.swift
//  AppKitViews
//
//  SF Symbols at a chosen size and weight.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSImage {
    /// The SF Symbol `name`, configured at `pointSize` and `weight` when a size is given, or nil
    /// when the name is not a symbol.
    static func symbol(
        _ name: String, pointSize: CGFloat? = nil, weight: NSFont.Weight = .regular,
        description: String? = nil
    ) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: description)
        guard let pointSize else { return image }
        return image?.withSymbolConfiguration(.init(pointSize: pointSize, weight: weight))
    }

    /// The context-menu glyph at the one menu icon size, 14 × 14 points.
    static func menuSymbol(_ name: String) -> NSImage? {
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return nil }
        image.size = NSSize(width: 14, height: 14)
        return image
    }
}
