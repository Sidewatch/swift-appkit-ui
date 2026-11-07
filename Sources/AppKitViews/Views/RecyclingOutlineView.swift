//
//  RecyclingOutlineView.swift
//  AppKitViews
//
//  An outline that hands its own disclosure buttons back instead of building new ones on
//  every reload.
//
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// An `NSOutlineView` that reuses its disclosure (and group show/hide) buttons.
///
/// Every outline in a host uses this or a subclass. A plain `NSOutlineView` builds a fresh
/// disclosure button for each expandable row it places after a `reloadData` (or a remove and
/// insert at the root) and never releases the old ones: measured, 200 reloads of a tree with 8
/// expandable rows left 1,608 buttons alive, each with its cell, image view, layout state and
/// gesture recogniser. AppKit asks for each button through `makeView(withIdentifier:owner:)`, so
/// this answers with one it handed out before that is no longer in a row; 16 were built for the
/// same run. Expanding and collapsing without a reload does not leak.
open class RecyclingOutlineView: NSOutlineView {
    /// Every disclosure and show/hide button this outline has handed out.
    private var outlineButtons: [NSView] = []

    /// How many outline buttons this outline has built; for a test.
    var outlineButtonsBuilt: Int { outlineButtons.count }

    /// Where a leaf row's icon is centred, from its cell's leading edge, to stand that icon in the
    /// disclosure column: set, a row that cannot expand starts its cell (in the outline column only) far
    /// enough left that the icon sits centred where a folder's chevron does at that level, so every name
    /// at a level starts at one x, as a tree without folder icons wants. Nil, cells sit where AppKit
    /// puts them. The host reloads after changing it.
    open var leafIconCentre: CGFloat?

    /// How far before a cell's leading edge AppKit centres the disclosure chevron of an outline row,
    /// measured on macOS 26 and 27 (`RecyclingOutlineViewTests` measures it again).
    public static let chevronCentreBeforeCell: CGFloat = 6.5

    open override func frameOfCell(atColumn column: Int, row: Int) -> NSRect {
        var frame = super.frameOfCell(atColumn: column, row: row)
        guard let centre = leafIconCentre, let outlineTableColumn, tableColumns.indices.contains(column),
            tableColumns[column] === outlineTableColumn, let item = item(atRow: row), !isExpandable(item)
        else { return frame }
        let pull = centre + Self.chevronCentreBeforeCell
        frame.origin.x -= pull
        frame.size.width += pull
        return frame
    }

    open override func makeView(withIdentifier identifier: NSUserInterfaceItemIdentifier, owner: Any?) -> NSView? {
        guard identifier == NSOutlineView.disclosureButtonIdentifier || identifier == NSOutlineView.showHideButtonIdentifier
        else { return super.makeView(withIdentifier: identifier, owner: owner) }
        if let free = outlineButtons.first(where: { $0.superview == nil && $0.identifier == identifier }) { return free }
        guard let made = super.makeView(withIdentifier: identifier, owner: owner) else { return nil }
        if !outlineButtons.contains(where: { $0 === made }) { outlineButtons.append(made) }
        return made
    }
}
