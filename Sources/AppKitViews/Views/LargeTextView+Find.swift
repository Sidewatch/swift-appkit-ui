//
//  LargeTextView+Find.swift
//  AppKitViews
//
//  LargeTextView: what a search found, marked, and the one moved to brought into view and selected.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

extension LargeTextView {
    /// Moves to the match at `range`, bytes into the source: scrolled into view, horizontally too, selected, and drawn
    /// as the current one.
    public func showMatch(_ range: Range<Int>) {
        currentMatch = range
        reveal(range)
        needsDisplay = true
    }

    /// Forgets the search: nothing marked, no current match.
    public func clearMatches() {
        matchFinder = nil
        currentMatch = nil
    }

    /// The selection as bytes into the source — empty for a caret — or nil when there is neither: where a search
    /// moves on from.
    public var selectionBytes: Range<Int>? {
        guard let anchor, let head, let from = byteOffset(of: min(anchor, head)), let to = byteOffset(of: max(anchor, head)) else {
            return nil
        }
        return from..<max(from, to)
    }

    /// The byte into the source at `position`: a whole line's column is a UTF-16 offset into its text, a long line's a
    /// byte offset already.
    func byteOffset(of position: LargeTextPosition) -> Int? {
        guard let source, let bytes = source.byteRange(ofLine: position.line) else { return nil }
        let column = max(0, position.column)
        guard bytes.count <= Self.wholeLineLimit else { return bytes.lowerBound + min(column, bytes.count) }
        var utf16 = 0
        var utf8 = 0
        for scalar in source.text(in: bytes).unicodeScalars where utf16 < column {
            utf16 += scalar.utf16.count
            utf8 += scalar.utf8.count
        }
        return bytes.lowerBound + utf8
    }

    /// Scrolls `range` into view and selects it.
    private func reveal(_ range: Range<Int>) {
        guard let source else { return }
        let line = source.line(containingByte: range.lowerBound)
        let model = layoutModel
        let distant = Double(line) < topLine - model.linesPerPage || Double(line) > topLine + 2 * model.linesPerPage
        scroll(toTop: distant ? model.topCentring(line) : model.topRevealing(line, from: topLine))
        guard var shown = shownLine(line) else { return }
        let from = range.lowerBound - shown.bytes.lowerBound
        let x = x(ofColumn: column(ofByte: from, in: shown), in: shown)
        if !shown.isWhole || x > textArea.maxX - characterWidth * 4 || x < textArea.minX {
            // Bring the match to a third of the way in: a long line's window is re-read for the new scroll.
            scroll(toLeft: CGFloat(from) * characterWidth - textArea.width / 3)
            shown = shownLine(line) ?? shown
        }
        let to = min(range.upperBound, shown.bytes.upperBound) - shown.bytes.lowerBound
        anchor = LargeTextPosition(line: line, column: column(ofByte: from, in: shown))
        head = LargeTextPosition(line: line, column: column(ofByte: to, in: shown))
        selectionChanged()
    }
}
