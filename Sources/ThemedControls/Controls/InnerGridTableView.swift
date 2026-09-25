//
//  InnerGridTableView.swift
//  ThemedControls
//
//  A table whose grid lines fall BETWEEN columns, never on its own outer edges.
//
//  Created by David Sherlock on 9/25/26.
//

import AppKit

/// A table whose vertical grid lines are dividers, not a frame (25 Sep 2026, David, of the CSV
/// preview: "should the furthest left one have another separator line? probably not").
///
/// `NSTableView.solidVerticalGridLineMask` rules every column boundary, the table's leading and
/// trailing edges included, so the first column wore a line down its left where nothing was being
/// divided — the same mistake as painting an outer edge with an inner-divider colour. This draws
/// the vertical lines itself, one on the trailing edge of every column BUT the last, matching
/// `ThemedTableHeaderCell`'s dividers above them. Horizontal lines stay AppKit's: set
/// `gridStyleMask = [.solidHorizontalGridLineMask]` and leave the vertical mask off.
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
