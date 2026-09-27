//
//  ThemedTableHeaderView.swift
//  ThemedControls
//
//  A table header that paints the palette's status background behind the column cells, so a
//  themed table has no system-grey strip above it.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A table header that paints the palette's status background behind the column cells, so a
/// themed table has no system-grey strip above it.
public final class ThemedTableHeaderView: NSTableHeaderView {
    public override func draw(_ dirtyRect: NSRect) {
        ThemedControls.palette.statusBackground.setFill()
        dirtyRect.fill()
        super.draw(dirtyRect)  // then the cells, which draw themselves below
    }
}
