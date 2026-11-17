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

    /// The SF Symbol `name` as ONE shared image, built on first use; nil when the name is not a
    /// symbol. For views that show the same few symbols in many rows: `NSImage(systemSymbolName:)`
    /// builds a new image on every call, which was most of the cost of reloading a list of file
    /// rows. The image is shared, so never change it (its size, its template flag): tint through
    /// the image view, and ask ``symbol(_:pointSize:weight:description:)`` for one to configure.
    @MainActor static func sharedSymbol(_ name: String) -> NSImage? {
        if let known = SharedSymbols.images[name] { return known }
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        SharedSymbols.images[name] = .some(image)
        return image
    }

    /// The context-menu glyph at the one menu icon size, 14 × 14 points.
    static func menuSymbol(_ name: String) -> NSImage? {
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return nil }
        image.size = NSSize(width: 14, height: 14)
        return image
    }
}

/// The images ``AppKit/NSImage/sharedSymbol(_:)`` has built, a name that is no symbol included.
@MainActor private enum SharedSymbols {
    static var images: [String: NSImage?] = [:]
}
