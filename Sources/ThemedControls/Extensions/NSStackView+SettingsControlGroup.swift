//
//  NSStackView+SettingsControlGroup.swift
//  ThemedControls
//
//  Controls grouped into one unit for a settings row's trailing edge.
//
//  Created by David Sherlock on 10/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

extension NSStackView {
    /// Groups controls into one unit for a row's trailing edge — a value and its stepper read as
    /// one control, not two that happen to be adjacent. For a pane, ``SettingsPane/controlGroup(_:spacing:)``.
    public static func settingsControlGroup(_ views: [NSView], spacing: CGFloat = 6) -> NSStackView {
        // Explicit rather than relying on the stack view to clear the flag as it adopts each
        // view: an autoresizing constraint that survives here is a silently broken row, not a
        // build error.
        views.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        let stack = NSStackView(views: views)
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }
}
