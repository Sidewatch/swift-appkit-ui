//
//  SettingsForm.swift
//  ThemedControls
//
//  Shared geometry for the Settings panes and the grouped-form primitives they are built from.
//
//  Created by David Sherlock on 7/17/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

// MARK: - Geometry

/// Shared geometry for the Settings panes and the grouped-form primitives they
/// are built from.
public enum SettingsMetrics {
    /// One width for every pane — switching pages must not resize the window under
    /// the pointer, so panes share a width and shorter ones leave the rest of the
    /// page empty.
    public static let paneWidth: CGFloat = 620  // fills the sidebar window's content column without dead margins
    /// The floor a pane's height can reach, so a page never collapses to a sliver.
    public static let paneMinHeight: CGFloat = 360
    /// The window: ONE size for every page, a tall page scrolling inside it rather than the
    /// window resizing per page.
    // Appearance, Editor and Sidebar fit without scrolling; Terminal scrolls
    public static let windowSize = NSSize(width: 900, height: 660)
    /// The smallest the window may be dragged to.
    public static let windowMinSize = NSSize(width: 880, height: 460)  // sidebar + the 620-pt column with 20-pt margins
    /// The page list down the left edge.
    public static let sidebarWidth: CGFloat = 200
    /// The strip across the top that holds the traffic lights (over the sidebar) and the
    /// page's title (over the content); the window's title bar is transparent under it.
    public static let titleStripHeight: CGFloat = 52
    /// Page margin: window edge to card edge.
    public static let margin: CGFloat = 20
    /// A card's text inset. Captions and footnotes align to it, so they read as
    /// belonging to the card they sit against rather than to the page.
    public static let cardInset: CGFloat = 12
    /// Padding above and below a row's control line.
    public static let rowPadding: CGFloat = 8
    /// A row's control line. Fixed rather than fitted: the label and the control
    /// are centered in it, and the tallest control a pane uses (a stepper, 27pt)
    /// still fits — so no row is taller than its neighbours by a couple of points.
    public static let rowLineHeight: CGFloat = 30
    /// Gap from one section's last element to the next section's caption.
    public static let sectionGap: CGFloat = 18
    /// A card's corner radius.
    public static let cardRadius: CGFloat = 8
    /// A word list's visible height — deliberately shorter than its contents, so a long list
    /// scrolls rather than owning the whole pane.
    public static let listHeight: CGFloat = 140
    /// The wrap width for captions and footnotes: the card's text column.
    ///
    /// An AppKit wrapping label measures itself as a single line unless it is
    /// told the width to wrap at, and lays out clipped. The panes are a fixed
    /// width, so this is exact.
    public static let cardTextWidth: CGFloat = paneWidth - (margin + cardInset) * 2

    // MARK: - Surfaces (themed, not system)
    //
    // From the palette, not the system window colour, which is wallpaper-tinted.

    /// The recessed page the cards sit on.
    public static var pageBackground: NSColor { ThemedControls.palette.pageBackground }

    /// A card's fill, raised off the page: lighter than `pageBackground` in a dark palette,
    /// a shade darker in a light one.
    public static var cardFill: NSColor { ThemedControls.palette.cardBackground }

    /// One device pixel, in points. Read from the main screen, not a view's window: separators
    /// are pinned at construction, before they have a window. 2× when there is no screen.
    public static var hairline: CGFloat { 1 / (NSScreen.main?.backingScaleFactor ?? 2) }
}
