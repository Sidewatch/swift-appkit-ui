//
//  InnerGridTableView.swift
//  ThemedControls
//
//  A table whose grid lines fall BETWEEN columns, never on its own outer edges.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A table whose vertical grid lines are dividers between columns, not a frame around them.
///
/// `solidVerticalGridLineMask` also rules the table's outer edges, where nothing is divided. This
/// draws one line on the trailing edge of every column BUT the last, matching
/// `ThemedTableHeaderCell`'s dividers. Set `gridStyleMask = [.solidHorizontalGridLineMask]` only.
public final class InnerGridTableView: NSTableView {
    /// The colour of the vertical dividers; the palette's row separator by default.
    public var dividerColor: NSColor?

    public override func drawGrid(inClipRect clipRect: NSRect) {
        super.drawGrid(inClipRect: clipRect)   // the horizontal lines, per the mask
        guard tableColumns.count > 1 else { return }
        (dividerColor ?? ThemedControls.palette.rowSeparator).setFill()
        for column in 0..<(tableColumns.count - 1) {
            let x = rect(ofColumn: column).maxX - 1
            guard x >= clipRect.minX, x < clipRect.maxX else { continue }
            NSRect(x: x, y: clipRect.minY, width: 1, height: clipRect.height).fill()
        }
    }

    /// The x of every divider this table would draw, for a caller that measures them.
    public var dividerXsForTesting: [CGFloat] {
        guard tableColumns.count > 1 else { return [] }
        return (0..<(tableColumns.count - 1)).map { rect(ofColumn: $0).maxX - 1 }
    }
}
