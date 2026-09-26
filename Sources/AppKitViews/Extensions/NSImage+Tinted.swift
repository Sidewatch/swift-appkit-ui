//
//  NSImage+Tinted.swift
//  AppKitViews
//
//  A copy of an image painted in one colour.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSImage {
    /// A copy painted in `color`. A template symbol drawn by hand, or placed in attributed text,
    /// needs this, since `contentTintColor` belongs to image views and buttons.
    func tinted(_ color: NSColor) -> NSImage {
        let out = NSImage(size: size, flipped: false) { rect in
            self.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
        out.isTemplate = false
        return out
    }
}
