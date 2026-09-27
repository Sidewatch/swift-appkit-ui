//
//  ThemedRowView.swift
//  ThemedControls
//
//  The themed table-row selection every list draws, in one place.
//
//  Created by David Sherlock on 8/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A table row that paints the app's selection style.
///
/// Nine lists had written this by hand, and the copies had already drifted three ways with
/// no design intent recorded for most of it: the leading accent bar was 3pt in some, 2pt in
/// one (deliberately — 22pt rows), and absent in five; and `interiorBackgroundStyle` was
/// overridden in some but not others, which decides whether AppKit inverts the row's text
/// on selection. The result was that visually identical lists selected differently.
///
/// Not `final`: `GitChangeRowView` extends it with hover tracking.
open class ThemedRowView: NSTableRowView {

    /// Width of the leading accent bar; 0 draws none.
    ///
    /// A parameter rather than a constant because the one intentional difference among the
    /// copies was real: the outline's 22pt rows use 2pt so the bar stays proportionate,
    /// where the taller list rows use 3pt.
    public let accentBar: CGFloat

    public init(accentBar: CGFloat = 0) {
        self.accentBar = accentBar
        super.init(frame: .zero)
    }

    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

    open override func drawSelection(in dirtyRect: NSRect) {
        guard isSelected else { return }
        ThemedControls.palette.selection.setFill()
        bounds.fill()
        guard accentBar > 0 else { return }
        ThemedControls.palette.accent.withAlphaComponent(0.8).setFill()
        NSRect(x: 0, y: 0, width: accentBar, height: bounds.height).fill()
    }

    /// Selected rows keep emphasized interior styling so their labels invert consistently.
    /// Previously set on some copies and not others, which is why the same-looking lists
    /// rendered selected text differently.
    open override var interiorBackgroundStyle: NSView.BackgroundStyle { .emphasized }
}

/// `ThemedRowView` that reports emphasized interior styling only while SELECTED.
/// For lists whose cells set explicit theme colors on their labels: macOS 26's
/// AppKit forces such labels white under unconditional emphasis (the file tree
/// shipped that bug for an evening). The base class keeps the unconditional
/// behavior for the lists built against it.
open class ThemedSelectionRowView: ThemedRowView {
    open override var interiorBackgroundStyle: NSView.BackgroundStyle { isSelected ? .emphasized : .normal }
}

/// A section-header row painted with the theme's sidebar surface. Opaque on
/// purpose: group rows float over scrolled content, and a clear background
/// would let entry text bleed through the floating header. (Born in the Skills
/// pane; survives it in the Library.)
/// A group header as a full-width BAND — VS Code's section-header look — rather than a
/// caption floating in the list: a lift of the sidebar surface with a hairline above
/// and below, so a group reads as a shelf the rows sit under.
public final class ThemedGroupRowView: NSTableRowView {
    public override func drawBackground(in dirtyRect: NSRect) {
        ThemedControls.palette.sidebarBackground.setFill()
        bounds.fill()
        ThemedControls.palette.sidebarBackground.blended(ThemedControls.palette.isDark ? 0.06 : 0.035, toward: ThemedControls.palette.foreground).setFill()
        bounds.fill()
        ThemedControls.palette.rowSeparator.setFill()
        NSRect(x: 0, y: 0, width: bounds.width, height: 1).fill()
        NSRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1).fill()
    }
}
