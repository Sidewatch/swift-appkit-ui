//
//  ThemedTableHeaderCell.swift
//  ThemedControls
//
//  A column header that paints its own background, hairlines and sort indicator from the
//  palette, because the stock cell paints a system one over whatever the header view filled.
//
//  Created by David Sherlock on 9/17/26.
//

import AppKit

/// A column header drawn entirely from the palette.
///
/// `ThemedTableHeaderView` fills the palette's status background, but `NSTableHeaderCell` then
/// paints its OWN system background, separator and bottom border over the top of it — so the
/// header still read as a strip of a different app. Measured off a screenshot of the database
/// viewer: the header band came out `#404041` and its separators `#626261`, both neutral system
/// greys, above rows at `#363A42` and a sidebar at `#2D3138` (17 Sep 2026).
///
/// The cell therefore paints everything itself. The one thing a naive `draw(withFrame:in:)`
/// override loses is the sort-indicator arrow — the table still sorts, but nothing says so,
/// which reads as "clicking the header does nothing" — so the indicator is drawn back
/// explicitly from the table's own indicator state.
public final class ThemedTableHeaderCell: NSTableHeaderCell {

    /// Extra leading padding for the title, on top of the inset `NSTableHeaderCell` applies.
    ///
    /// A header cell and a row's cell view inset their text by different amounts, so a title
    /// sits left of the column it labels unless the host says by how much: the database grid's
    /// cells start their text 6pt further in than the header does, which read as a wonky grid
    /// (David, 17 Sep 2026). `--dump-header-paint` in Sidewatch measures both and prints the
    /// gap, so the number is checked rather than guessed.
    public var titleInset: CGFloat = 0

    /// A header cell whose title is already in the palette's colours.
    public convenience init(title: String, titleInset: CGFloat = 0) {
        self.init(textCell: title)
        attributedStringValue = Self.title(title)
        self.titleInset = titleInset
    }

    /// A column title in the palette's colours — the string the cell draws, exposed so a host
    /// can retitle a column without rebuilding the cell.
    public static func title(_ text: String) -> NSAttributedString {
        // One weight step up from the palette's small font: a column title should read as a
        // label above its data rather than as more caption text. `convertWeight` keeps the
        // face if the host installed a custom one, and returns the font unchanged when it
        // cannot go heavier.
        let font = NSFontManager.shared.convertWeight(true, of: ThemedControls.palette.smallFont)
        return NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: ThemedControls.palette.statusText,
        ])
    }

    public override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        let palette = ThemedControls.palette
        // Pressed state is drawn here too: with the system background gone, a header that did
        // not react to a click would read as dead.
        let background = isHighlighted
            ? palette.statusBackground.blended(palette.isDark ? 0.10 : 0.06, toward: palette.foreground)
            : palette.statusBackground
        background.setFill()
        cellFrame.fill()

        // The header view is flipped, so `maxY` is the bottom edge: the hairline that separates
        // the header from the first row.
        palette.border.setFill()
        NSRect(x: cellFrame.minX, y: cellFrame.maxY - 1, width: cellFrame.width, height: 1).fill()
        // A shorter rule between columns, inset so it reads as a divider between titles rather
        // than a full-height grid line. Only for a real column: under the `.automatic` table
        // style AppKit draws this same cell for the 10pt inset strips at either end, and a
        // divider there is a hairline floating in empty space.
        // …and never after the LAST column: that edge is the table's, not a boundary between
        // two titles (25 Sep 2026, with the body's grid).
        if isColumnRect(cellFrame, in: controlView), !isLastColumn(in: controlView) {
            palette.rowSeparator.setFill()
            NSRect(x: cellFrame.maxX - 1, y: cellFrame.minY + 5, width: 1, height: max(0, cellFrame.height - 11)).fill()
        }

        var interior = cellFrame
        interior.origin.x += titleInset
        interior.size.width = max(0, interior.width - titleInset)
        if let ascending = sortIndicatorAscending(in: controlView) {
            let rect = sortIndicatorRect(forBounds: cellFrame)
            drawSortIndicator(withFrame: rect, in: controlView, ascending: ascending, priority: 0)
            interior.size.width = max(0, rect.minX - interior.minX)
        }
        // Centre the title ourselves. Handed the whole cell, `drawInterior` pins the text to
        // the TOP — the stock `draw(withFrame:in:)` centres it before calling through, and
        // that step is lost with the override. Measured: in a 28pt header the title's ink sat
        // centred on 6.5pt where the stock cell's sat on 13.5pt, i.e. a title riding high in
        // its band with empty space beneath it (David, 17 Sep 2026).
        let titleHeight = ceil(attributedStringValue.size().height)
        if titleHeight > 0, titleHeight < interior.height {
            interior.origin.y += ((interior.height - titleHeight) / 2).rounded(.down)
            interior.size.height = titleHeight
        }
        // `drawInterior` paints the system pressed background when the cell is highlighted —
        // measured: a pressed themed header came back #454545 even though this method had just
        // filled the palette colour. Drop the flag for the length of the title draw; the fill
        // above has already said "pressed" in the palette's own terms.
        let pressed = isHighlighted
        isHighlighted = false
        drawInterior(withFrame: interior, in: controlView)
        isHighlighted = pressed
    }

    /// Whether this cell's column is the last one — its trailing edge is the table's edge.
    private func isLastColumn(in controlView: NSView) -> Bool {
        guard let header = controlView as? NSTableHeaderView, let table = header.tableView,
              let index = table.tableColumns.firstIndex(where: { $0.headerCell === self }) else { return false }
        return index == table.tableColumns.count - 1
    }

    /// Whether `frame` is the rect of the column this cell belongs to, rather than one of the
    /// filler strips the `.automatic` style draws at either end of the header.
    private func isColumnRect(_ frame: NSRect, in controlView: NSView) -> Bool {
        guard let header = controlView as? NSTableHeaderView,
              let table = header.tableView,
              let index = table.tableColumns.firstIndex(where: { $0.headerCell === self }) else { return true }
        return header.headerRect(ofColumn: index).equalTo(frame)
    }

    /// The sort direction to draw for this cell's column, or nil when the table has set no
    /// indicator on it. Found by identity (`headerCell === self`) because a cell is not told
    /// which column owns it.
    func sortIndicatorAscending(in controlView: NSView) -> Bool? {
        guard let header = controlView as? NSTableHeaderView,
              let table = header.tableView,
              let column = table.tableColumns.first(where: { $0.headerCell === self }),
              table.indicatorImage(in: column) != nil else { return nil }
        let key = column.sortDescriptorPrototype?.key
        return table.sortDescriptors.first { $0.key == key }?.ascending ?? true
    }
}
