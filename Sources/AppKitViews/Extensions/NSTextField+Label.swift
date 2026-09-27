//
//  NSTextField+Label.swift
//  AppKitViews
//
//  A styled, non-editable label in one call.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSTextField {
    /// A non-editable label with its font, colour and line handling set — the four lines every
    /// label otherwise repeats. Nil arguments keep AppKit's label defaults.
    static func label(
        _ text: String,
        font: NSFont? = nil,
        color: NSColor? = nil,
        lineBreak: NSLineBreakMode? = nil,
        alignment: NSTextAlignment? = nil
    ) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        if let font { label.font = font }
        if let color { label.textColor = color }
        if let lineBreak { label.lineBreakMode = lineBreak }
        if let alignment { label.alignment = alignment }
        return label
    }
}
