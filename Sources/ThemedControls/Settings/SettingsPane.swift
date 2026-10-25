//
//  SettingsPane.swift
//  ThemedControls
//
//  One section of the Settings window. Panes own their controls and write straight through to the
//  setting stores (`ThemeManager`, `ScanSettings`, `TerminalSettings`) — every edit applies live,
//  so there is no OK/Apply.
//
//  Created by David Sherlock on 7/17/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// One page of a Settings window. Panes own their controls and write straight through to the
/// host's setting stores — every edit applies live, so there is no OK/Apply.
public protocol SettingsPane: NSViewController {
    /// The sidebar row's title (and the page's heading).
    var paneTitle: String { get }
    /// The sidebar row's SF Symbol.
    var paneSymbol: String { get }
    /// Pull every control's value from the setting store. Called before the
    /// window is shown, so a pane can never display a stale value.
    func syncFromSettings()
}

/// The grouped-form building blocks every pane lays itself out with.
extension SettingsPane {

    /// Lays the pane out as grouped-form sections down the page: caption, card,
    /// footnote, next section. Content is top-aligned and the page is a fixed
    /// size, so a short pane leaves the rest of the window empty rather than
    /// stretching its rows apart.
    public func buildPane(_ sections: [SettingsSection]) {
        // The window is a fixed size, so the sections live in a flipped documentView inside a
        // borderless, background-less scroll view: a tall pane scrolls instead of being clipped.
        let content = SettingsScrollContent()  // isFlipped → lays out top-down
        content.translatesAutoresizingMaskIntoConstraints = false
        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        // Legacy, not overlay: an overlay scroller shows only while scrolling, so an overflowing
        // page looks clipped rather than scrollable. A legacy scroller stands whenever the page
        // overflows and autohides when it fits. The window's appearance styles it.
        scroll.scrollerStyle = .legacy
        scroll.documentView = content
        view.addSubview(scroll)

        // The sections, a margin in from each side; the content takes their height plus a margin
        // above and below. The content is the page's width, not the clip view's: the view is a
        // scroller's gutter wider, so a scroller appearing never narrows the cards or moves their
        // controls.
        let sections = SettingsSectionsView(sections: sections)
        content.addSubview(sections)
        var constraints: [NSLayoutConstraint] = [
            sections.topAnchor.constraint(equalTo: content.topAnchor, constant: SettingsMetrics.margin),
            sections.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            sections.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: sections.bottomAnchor, constant: SettingsMetrics.margin),
        ]
        constraints += [
            content.widthAnchor.constraint(equalToConstant: SettingsMetrics.paneWidth),
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        pinPaneSize()
    }

    /// The height this pane's content actually needs, at least ``SettingsMetrics/paneMinHeight``.
    ///
    /// Measured on the document view, NOT `view.fittingSize`: a scroll view reports a MINIMAL
    /// fitting size rather than its document's.
    public var contentHeight: CGFloat {
        func findContent(_ v: NSView) -> SettingsScrollContent? {
            if let c = v as? SettingsScrollContent { return c }
            for sub in v.subviews { if let c = findContent(sub) { return c } }
            return nil
        }
        guard let content = findContent(view) else { return SettingsMetrics.paneMinHeight }
        view.layoutSubtreeIfNeeded()
        // The bottom margin is already in the constraints (see the content.bottomAnchor pin in
        // buildPane), so this is the full height including trailing space.
        return max(content.fittingSize.height, SettingsMetrics.paneMinHeight)
    }

    /// A section's caption, above its card.
    public func sectionHeader(_ text: String) -> NSTextField { SettingsSectionsView.header(text) }

    /// Groups controls into one unit for a row's trailing edge — a value and its
    /// stepper read as one control, not two that happen to be adjacent.
    public func controlGroup(_ views: [NSView], spacing: CGFloat = 6) -> NSView {
        NSStackView.settingsControlGroup(views, spacing: spacing)
    }

    /// Pins the pane's width (``SettingsMetrics/columnWidth``: the page and its scroller's
    /// gutter) — shared by every pane, so switching pages doesn't resize the window under the
    /// pointer, and a page that scrolls keeps the cards where one that fits has them.
    ///
    /// Height must NOT be pinned: a fixed height fights the container's fill when the window is
    /// resized. A low-priority floor stops the pane collapsing and lets the scroll view take growth.
    public func pinPaneSize() {
        let floor = view.heightAnchor.constraint(greaterThanOrEqualToConstant: SettingsMetrics.paneMinHeight)
        floor.priority = .defaultLow
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: SettingsMetrics.columnWidth),
            floor,
        ])
    }
}
