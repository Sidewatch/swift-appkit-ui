//
//  NSTableView+ReusableView.swift
//  AppKitViews
//
//  Row views and cells handed back from the table's reuse queue, so a list that scrolls or
//  reloads keeps only what it shows.
//
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

extension NSTableView {
    /// A row view or cell the table has finished with when there is one, else `make()`'s,
    /// tagged so it can come back. The identifier is the view type's name plus `variant`, so a
    /// table that makes two kinds of the same type (two accent widths, a header and an item)
    /// gets each kind back.
    ///
    /// **Every row-view factory returns through this.** A row view the table no longer shows is
    /// parked in its row-view purgatory, and only a row view handed back out of
    /// `makeView(withIdentifier:owner:)` and returned again ever leaves it: built afresh, every
    /// row view the list scrolled past stays alive, each with its own layout engine and layer
    /// contents (measured on a 400-row list scrolled 300 times: 6,897 built, 6,874 alive;
    /// through this, 23 built). A reload is not the leak (the table drops its row views then);
    /// scrolling, `scrollRowToVisible` included, is. Dequeuing and then dropping the parked row
    /// does not release it either; it must be returned.
    ///
    /// **A cell that is replaced while its row stays (a scroll that reuses the row, a
    /// `reloadData(forRowIndexes:columnIndexes:)`) should come through this too.** Each cell a
    /// row ever hosted leaves three dependency records on the row (`_inSelectedTableRow`,
    /// `_effectiveSemanticContext`, `_effectiveGlassMaterialContext`) that nothing removes while
    /// the row lives: about 300 of each per row after 300 placements of fresh cells, one of each
    /// with reused ones.
    ///
    /// The table resets selection and the other row state it owns before handing a view back;
    /// the caller reconfigures a reused cell in full, and a subclass with state of its own resets
    /// it in `prepareForReuse()`.
    @MainActor
    public func reusableView<View: NSView>(variant: String = "", _ make: () -> View) -> View {
        let name = String(reflecting: View.self)
        let identifier = NSUserInterfaceItemIdentifier(variant.isEmpty ? name : "\(name).\(variant)")
        if let reused = makeView(withIdentifier: identifier, owner: nil) as? View { return reused }
        let view = make()
        view.identifier = identifier
        return view
    }
}
