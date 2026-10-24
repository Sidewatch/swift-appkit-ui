//
//  NSMenu+Separators.swift
//  AppKitViews
//
//  Hiding the separators that hidden items leave with nothing to separate.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSMenu {
    /// Hides every separator that would draw with nothing to separate once some items are hidden —
    /// one before any shown item, one after the last, and all but the first of a run — and shows
    /// every other separator again, so it can be called after each change to what is hidden.
    ///
    /// A menu whose groups come and go (items hidden by a setting) otherwise keeps a line at its
    /// top, its bottom, or two in a row, which AppKit draws as they are.
    func hideRedundantSeparators() {
        var shownSinceSeparator = false
        var pending: NSMenuItem?
        for item in items {
            if item.isSeparatorItem {
                item.isHidden = true
                if shownSinceSeparator { pending = item }
                shownSinceSeparator = false
            } else if !item.isHidden {
                pending?.isHidden = false
                pending = nil
                shownSinceSeparator = true
            }
        }
    }
}
