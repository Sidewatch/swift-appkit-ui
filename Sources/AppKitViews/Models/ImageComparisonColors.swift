//
//  ImageComparisonColors.swift
//  AppKitViews
//
//  The colours an image comparison draws with.
//
//  Created by David Sherlock on 10/22/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// The colours ``ImageComparisonView`` draws with, chosen by the host (its theme).
public struct ImageComparisonColors {
    /// Behind everything.
    public var background: NSColor
    /// The two squares of the checkerboard behind a picture, so its clear pixels read as clear.
    public var checkerLight: NSColor
    /// See ``checkerLight``.
    public var checkerDark: NSColor
    /// The swipe divider and its handle.
    public var divider: NSColor
    /// The changed pixels in ``ImageComparisonMode/changes``.
    public var change: NSColor
    /// The captions.
    public var caption: NSColor

    /// Colours from their parts.
    public init(background: NSColor, checkerLight: NSColor, checkerDark: NSColor, divider: NSColor, change: NSColor, caption: NSColor) {
        self.background = background
        self.checkerLight = checkerLight
        self.checkerDark = checkerDark
        self.divider = divider
        self.change = change
        self.caption = caption
    }
}
