//
//  SettingsSidebarRowView.swift
//  ThemedControls
//
//  A settings sidebar row: the accent fill when selected.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A page row: the accent fill, rounded and inset, when selected — drawn here because the
/// table's own highlight paints the SYSTEM accent, which no theme can tint.
public final class SettingsSidebarRowView: NSTableRowView {
    override public var isEmphasized: Bool {
        get { true }
        set {}
    }
    override public func drawSelection(in dirtyRect: NSRect) {}
    override public func drawBackground(in dirtyRect: NSRect) {
        guard isSelected else { return }
        ThemedControls.palette.accent.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 8, dy: 0), xRadius: 6, yRadius: 6).fill()
    }
    override public var isSelected: Bool { didSet { needsDisplay = true } }
}
