//
//  NSMenu+Items.swift
//  AppKitViews
//
//  Appending a targeted, optionally glyphed menu item in one call.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSMenu {
    /// Appends an item targeting `target`, with an optional SF Symbol glyph at the menu size.
    ///
    /// A nil or unknown `symbol` yields no image, so a typo degrades to a text-only item rather
    /// than failing to build the menu.
    ///
    /// - Parameters:
    ///   - title: Item title.
    ///   - action: Selector sent to `target`.
    ///   - target: Receiver; menu items do not retain it.
    ///   - symbol: SF Symbol name for the glyph.
    ///   - key: Key equivalent, empty for none.
    ///   - represented: Stored on `representedObject`, usually the row or model the action needs.
    /// - Returns: The appended item, for callers that set state or a tag.
    @discardableResult
    func addItem(_ title: String, action: Selector, target: AnyObject?, symbol: String? = nil,
                 key: String = "", represented: Any? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = target
        if let symbol { item.image = .menuSymbol(symbol) }
        item.representedObject = represented
        addItem(item)
        return item
    }
}
