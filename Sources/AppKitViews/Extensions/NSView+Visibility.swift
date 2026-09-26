//
//  NSView+Visibility.swift
//  AppKitViews
//
//  Whether a person could see a view right now.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSView {
    /// True when the view is on screen for the person: in a visible window, neither it nor an
    /// ancestor hidden, and some of it inside its visible rect. `isHidden` alone answers only for
    /// the view itself, and a view in a closed window or scrolled fully out of sight is not hidden.
    var isVisibleToUser: Bool {
        window?.isVisible == true && !isHiddenOrHasHiddenAncestor && !visibleRect.isEmpty
    }
}
