//
//  SettingsForm.swift
//  ThemedControls
//
//  Shared geometry for the Settings panes and the grouped-form primitives they are built from.
//
//  Created by David Sherlock on 7/17/26.
//

import AppKit

// MARK: - Geometry

/// Shared geometry for the Settings panes and the grouped-form primitives they
/// are built from.
public enum SettingsMetrics {
    /// One width for every pane — switching tabs must not resize the window under
    /// the pointer, so panes share a width and shorter ones leave the rest of the
    /// page empty.
    public static let paneWidth: CGFloat = 620   // 540 until 22 Sep 2026: in the sidebar window the cards sat in a narrow column between dead margins
    /// The floor a pane's height can reach, so a page never collapses to a sliver.
    public static let paneMinHeight: CGFloat = 360
    /// The window (22 Sep 2026, the sidebar layout): ONE size for every page, the page
    /// scrolling inside it — the tab strip's window resized itself to each pane (412…911 pt).
    public static let windowSize = NSSize(width: 900, height: 660)   // Appearance, Editor and Sidebar fit without scrolling; Terminal scrolls
    public static let windowMinSize = NSSize(width: 880, height: 460)   // sidebar + the 620-pt column with 20-pt margins
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
    public static let cardRadius: CGFloat = 8
    /// The skip list's visible height — deliberately shorter than its contents.
    /// The shipped list is ~16 names; a card that grew to fit them would own the
    /// whole pane.
    public static let listHeight: CGFloat = 140
    /// The wrap width for captions and footnotes: the card's text column.
    ///
    /// An AppKit wrapping label measures itself as a single line unless it is
    /// told the width to wrap at, and lays out clipped. The panes are a fixed
    /// width, so this is exact.
    public static let cardTextWidth: CGFloat = paneWidth - (margin + cardInset) * 2

    // MARK: - Surfaces (themed, not system)
    //
    // Every other surface in the app paints from `Theme`; Settings did not, so it
    // took the wallpaper-tinted system window color (a brown page under an orange
    // desktop). These two read `Theme` so the page and cards match the rest.

    /// The recessed page the cards sit on.
    public static var pageBackground: NSColor { ThemedControls.palette.pageBackground }

    /// A card's fill: the page lifted toward the foreground so it reads as a
    /// raised surface. In a dark palette this lands lighter than the page (the
    /// lift the old Dark-Aqua hand-roll faked); in a light one a shade darker —
    /// either way a resolved tone distinct from `pageBackground`, in both
    /// polarities (proven in `SettingsColorHarness`).
    public static var cardFill: NSColor { ThemedControls.palette.cardBackground }

    /// One device pixel, in points — a real hairline on Retina rather than the
    /// 2px a literal `1` produces there. Read from the main screen rather than a
    /// view's window: separators are pinned at construction, before the view has
    /// a window, and settings never moves between displays mid-layout. Falls back
    /// to 2× (the only scale any shipping Mac uses) if there's no screen.
    public static var hairline: CGFloat { 1 / (NSScreen.main?.backingScaleFactor ?? 2) }
}

// MARK: - Section

// MARK: - Card

// MARK: - Separator

// MARK: - Row

// MARK: - Themed primitives

