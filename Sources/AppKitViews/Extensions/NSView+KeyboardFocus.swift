//
//  NSView+KeyboardFocus.swift
//  AppKitViews
//
//  Whether the keyboard is somewhere inside a view.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSView {
    /// Whether the window's first responder is this view or anything inside it — a text field being
    /// edited counts, since its field editor sits inside the field. False when the first responder is
    /// not a view (the window itself) or the view has no window.
    var containsKeyboardFocus: Bool {
        guard let responder = window?.firstResponder as? NSView else { return false }
        return responder.isDescendant(of: self)  // true for the view itself too
    }
}
