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

/// A table row that paints the palette's selection style, with an optional leading accent bar,
/// so every list selects the same way. Open for subclasses that add behaviour (hover tracking).
open class ThemedRowView: NSTableRowView {

    /// Width of the leading accent bar; 0 draws none. 22-pt outline rows use 2 pt so the bar stays
    /// proportionate, taller list rows 3 pt.
    public let accentBar: CGFloat

    /// Creates a row with a leading accent bar `accentBar` points wide (0 for none).
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

    /// Always emphasized, so every list built on this inverts its labels the same way.
    open override var interiorBackgroundStyle: NSView.BackgroundStyle { .emphasized }
}

/// `ThemedRowView` that reports emphasized interior styling only while SELECTED. For lists whose
/// cells set explicit theme colours on their labels: macOS 26 forces such labels white under
/// unconditional emphasis.
open class ThemedSelectionRowView: ThemedRowView {
    open override var interiorBackgroundStyle: NSView.BackgroundStyle { isSelected ? .emphasized : .normal }
}

/// A group header as a full-width BAND — a lift of the sidebar surface with a hairline above and
/// below. Opaque on purpose: group rows float over scrolled content, which must not show through.
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
