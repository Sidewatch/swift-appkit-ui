//
//  ControlPalette.swift
//  ThemedControls
//
//  The colours and fonts every themed control reads, supplied by the host app's theme.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// What a themed control needs to know about the current theme. The host installs one as
/// `ThemedControls.palette` and posts `ThemedControls.paletteDidChange` when it changes;
/// every control reads the palette live, so a theme switch is one repaint away.
public protocol ControlPalette: Sendable {
    /// Whether the theme is dark — picks scroller knob styles and blend directions.
    var isDark: Bool { get }
    /// The theme's accent: selected segments, a switch or checkbox when on, slider fills.
    var accent: NSColor { get }
    /// Primary text.
    var foreground: NSColor { get }
    /// The fill behind a selected row.
    var selection: NSColor { get }
    /// The sidebar surface; also group-row bands.
    var sidebarBackground: NSColor { get }
    /// Secondary text on the sidebar surface, such as placeholders and glyphs.
    var sidebarText: NSColor { get }
    /// Text on the status bar and table headers.
    var statusText: NSColor { get }
    /// The recessed outline at a surface's edge.
    var border: NSColor { get }
    /// Hairlines between rows and dividers inside a raised surface.
    var rowSeparator: NSColor { get }
    /// Text that should recede: placeholders, hints, a pop-up's secondary label.
    var mutedText: NSColor { get }
    /// The status bar's background, also used for table headers.
    var statusBackground: NSColor { get }

    /// The page a settings form sits on.
    var pageBackground: NSColor { get }
    /// A card raised off that page. It must differ from `pageBackground` or the cards vanish.
    var cardBackground: NSColor { get }
    /// The small UI font (captions, secondary buttons).
    var smallFont: NSFont { get }
    /// A surface lifted off the background: the foreground blended in by `dark` on a dark
    /// theme and by `light` on a light one (chips, fields, segment bars).
    func elevatedSurface(dark: CGFloat, light: CGFloat) -> NSColor
}

/// Defaults for the settings-form surfaces.
extension ControlPalette {
    /// Defaults so an existing palette keeps compiling. A host that draws settings forms should
    /// answer properly: a card the same colour as its page is not a card.
    public var pageBackground: NSColor { statusBackground }
    /// Defaults to the sidebar surface; see `pageBackground`.
    public var cardBackground: NSColor { sidebarBackground }
}
