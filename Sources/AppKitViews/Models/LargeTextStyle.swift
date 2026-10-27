//
//  LargeTextStyle.swift
//  AppKitViews
//
//  How a large text view draws: its font and colours.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// How a ``LargeTextView`` draws: one monospaced font and the host's colours.
public struct LargeTextStyle {
    /// The one font every line is drawn in; monospaced, so a column is a character.
    public var font: NSFont
    /// The text's colour.
    public var text: NSColor
    /// The text area's fill.
    public var background: NSColor
    /// The gutter's line numbers.
    public var lineNumbers: NSColor
    /// The gutter's fill.
    public var gutter: NSColor
    /// Behind selected text.
    public var selection: NSColor
    /// Behind every find match on screen.
    public var match: NSColor
    /// Behind the match find last moved to.
    public var currentMatch: NSColor
    /// Spaces a tab stands for.
    public var tabWidth: Int

    /// A style from its font and colours.
    public init(
        font: NSFont, text: NSColor, background: NSColor, lineNumbers: NSColor, gutter: NSColor, selection: NSColor, match: NSColor,
        currentMatch: NSColor, tabWidth: Int = 4
    ) {
        self.font = font
        self.text = text
        self.background = background
        self.lineNumbers = lineNumbers
        self.gutter = gutter
        self.selection = selection
        self.match = match
        self.currentMatch = currentMatch
        self.tabWidth = tabWidth
    }

    /// The system's text colours in a 12-point monospaced font.
    public static var system: LargeTextStyle {
        LargeTextStyle(
            font: .mono(12), text: .textColor, background: .textBackgroundColor,
            lineNumbers: .secondaryLabelColor, gutter: .textBackgroundColor, selection: .selectedTextBackgroundColor,
            match: .findHighlightColor.withAlphaComponent(0.35), currentMatch: .findHighlightColor)
    }
}
