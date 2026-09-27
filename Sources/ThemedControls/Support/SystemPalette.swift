//
//  SystemPalette.swift
//  ThemedControls
//
//  A palette from the system colours, so the controls work before a host installs one.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// The macOS system colours as a palette: what a control looks like with nothing installed.
public struct SystemPalette: ControlPalette {
    /// Creates the system palette.
    public init() {}
    public var isDark: Bool { NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua }
    public var accent: NSColor { .controlAccentColor }
    public var foreground: NSColor { .labelColor }
    public var selection: NSColor { .selectedContentBackgroundColor }
    public var sidebarBackground: NSColor { .windowBackgroundColor }
    public var sidebarText: NSColor { .secondaryLabelColor }
    public var statusText: NSColor { .secondaryLabelColor }
    public var border: NSColor { .separatorColor }
    public var rowSeparator: NSColor { .separatorColor }
    public var mutedText: NSColor { .tertiaryLabelColor }
    public var statusBackground: NSColor { .windowBackgroundColor }
    public var smallFont: NSFont { .systemFont(ofSize: NSFont.smallSystemFontSize) }
    public func elevatedSurface(dark: CGFloat, light: CGFloat) -> NSColor {
        NSColor.windowBackgroundColor.blended(isDark ? dark : light, toward: .labelColor)
    }
}
