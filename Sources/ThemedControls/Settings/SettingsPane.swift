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
        let content = SettingsScrollContent()   // isFlipped → lays out top-down
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

        var constraints: [NSLayoutConstraint] = []
        var previous: NSView?

        /// Pins one page element full width under the last one, inside the scrolling
        /// content. `inset` indents captions and footnotes to the card's text column.
        func place(_ element: NSView, gap: CGFloat, inset: CGFloat = 0) {
            element.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(element)
            constraints += [
                element.leadingAnchor.constraint(equalTo: content.leadingAnchor,
                                                 constant: SettingsMetrics.margin + inset),
                element.trailingAnchor.constraint(equalTo: content.trailingAnchor,
                                                  constant: -(SettingsMetrics.margin + inset)),
                element.topAnchor.constraint(equalTo: previous?.bottomAnchor ?? content.topAnchor,
                                             constant: gap),
            ]
            previous = element
        }

        for (index, section) in sections.enumerated() {
            let leading = index == 0 ? SettingsMetrics.margin : SettingsMetrics.sectionGap
            if let header = section.header {
                place(sectionHeader(header), gap: leading, inset: SettingsMetrics.cardInset)
                place(SettingsCard(rows: section.rows), gap: 6)
            } else {
                place(SettingsCard(rows: section.rows), gap: leading)
            }
            if let footnote = section.footnote {
                place(SettingsRowView.footnote(footnote), gap: 6, inset: SettingsMetrics.cardInset)
            }
        }
        // The last element sets the scrolling content's height (+ a bottom margin); the
        // content's width tracks the clip view so nothing ever scrolls horizontally.
        if let previous {
            constraints.append(content.bottomAnchor.constraint(equalTo: previous.bottomAnchor,
                                                               constant: SettingsMetrics.margin))
        }
        constraints += [
            content.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
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
    public func sectionHeader(_ text: String) -> NSTextField {
        let label = SettingsLabel(role: .secondary)
        label.stringValue = text
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        return label
    }

    /// Groups controls into one unit for a row's trailing edge — a value and its
    /// stepper read as one control, not two that happen to be adjacent.
    public func controlGroup(_ views: [NSView], spacing: CGFloat = 6) -> NSView {
        // Explicit rather than relying on the stack view to clear the flag as it
        // adopts each view: an autoresizing constraint that survives here is a
        // silently broken row, not a build error.
        views.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        let stack = NSStackView(views: views)
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    /// Pins the pane's width — shared by every pane, so switching pages doesn't resize the
    /// window under the pointer.
    ///
    /// Height must NOT be pinned: a fixed height fights the container's fill when the window is
    /// resized. A low-priority floor stops the pane collapsing and lets the scroll view take growth.
    public func pinPaneSize() {
        let floor = view.heightAnchor.constraint(greaterThanOrEqualToConstant: SettingsMetrics.paneMinHeight)
        floor.priority = .defaultLow
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: SettingsMetrics.paneWidth),
            floor,
        ])
    }
}

