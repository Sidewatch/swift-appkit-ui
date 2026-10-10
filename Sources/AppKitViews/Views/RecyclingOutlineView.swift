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

    open override func makeView(withIdentifier identifier: NSUserInterfaceItemIdentifier, owner: Any?) -> NSView? {
        guard identifier == NSOutlineView.disclosureButtonIdentifier || identifier == NSOutlineView.showHideButtonIdentifier
        else { return super.makeView(withIdentifier: identifier, owner: owner) }
        if let free = outlineButtons.first(where: { $0.superview == nil && $0.identifier == identifier }) { return free }
        guard let made = super.makeView(withIdentifier: identifier, owner: owner) else { return nil }
        if !outlineButtons.contains(where: { $0 === made }) { outlineButtons.append(made) }
        return made
    }
}
