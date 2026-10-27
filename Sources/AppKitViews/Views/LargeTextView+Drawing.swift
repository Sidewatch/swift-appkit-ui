//
//  LargeTextView+Drawing.swift
//  AppKitViews
//
//  LargeTextView: the lines on screen, read, set with Core Text and drawn with their selection and matches.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

extension LargeTextView {
    /// One line as the screen shows it: its text (the whole line, or the stretch of a long one that is on screen), set
    /// as a Core Text line, and where its first character is drawn.
    struct ShownLine {
        /// The 0-based line.
        let line: Int
        /// The line's bytes in the source.
        let bytes: Range<Int>
        /// What was decoded: the whole line, or a window into it.
        let text: String
        /// Whether `text` is the whole line; else a window of it starting `windowStart` bytes in.
        let isWhole: Bool
        let windowStart: Int
        let typeset: CTLine
        /// The view x of `text`'s first character.
        let x: CGFloat
    }

    /// `line` as the screen shows it, or nil for a line the source has not found.
    func shownLine(_ line: Int) -> ShownLine? {
        guard let source, let bytes = source.byteRange(ofLine: line) else { return nil }
        let origin = textArea.minX + LargeTextLayout.padding - leftX
        if bytes.count <= Self.wholeLineLimit {
            let text = source.text(in: bytes)
            return ShownLine(line: line, bytes: bytes, text: text, isWhole: true, windowStart: 0, typeset: typeset(text), x: origin)
        }
        // A long line: from the first column on screen, a screen's width of bytes (one a column in the ASCII such a
        // line nearly always is; four for any other character).
        let firstColumn = max(0, Int(leftX / characterWidth))
        let columns = Int(textArea.width / characterWidth) + 2
        let start = source.characterStart(atOrBefore: min(bytes.upperBound, bytes.lowerBound + firstColumn))
        let end = min(bytes.upperBound, start + columns * 4)
        let text = source.text(in: start..<end)
        let windowStart = start - bytes.lowerBound
        return ShownLine(
            line: line, bytes: bytes, text: text, isWhole: false, windowStart: windowStart, typeset: typeset(text),
            x: origin + CGFloat(windowStart) * characterWidth)
    }

    /// `text` in the style's font and colour, tabs at the style's width.
    private func typeset(_ text: String) -> CTLine {
        let paragraph = NSMutableParagraphStyle()
        paragraph.tabStops = []
        paragraph.defaultTabInterval = CGFloat(max(1, style.tabWidth)) * characterWidth
        let attributed = NSAttributedString(
            string: text, attributes: [.font: style.font, .foregroundColor: style.text, .paragraphStyle: paragraph])
        return CTLineCreateWithAttributedString(attributed)
    }

    /// The view x of `column` in a shown line: a UTF-16 offset into a whole line, a byte offset into a long one
    /// (clamped to the window on screen).
    func x(ofColumn column: Int, in shown: ShownLine) -> CGFloat {
        if shown.isWhole { return shown.x + CTLineGetOffsetForStringIndex(shown.typeset, min(column, shown.text.utf16.count), nil) }
        let inWindow = column - shown.windowStart
        guard inWindow > 0 else { return shown.x + CGFloat(min(0, inWindow)) * characterWidth }
        let utf8 = shown.text.utf8
        guard let index = utf8.index(utf8.startIndex, offsetBy: inWindow, limitedBy: utf8.endIndex) else {
            return shown.x + CTLineGetTypographicBounds(shown.typeset, nil, nil, nil) + CGFloat(inWindow - utf8.count) * characterWidth
        }
        return shown.x + CTLineGetOffsetForStringIndex(shown.typeset, index.utf16Offset(in: shown.text), nil)
    }

    /// The column of the byte `offset` into a shown line's bytes.
    func column(ofByte offset: Int, in shown: ShownLine) -> Int {
        guard shown.isWhole else { return offset }
        let utf8 = shown.text.utf8
        let index = utf8.index(utf8.startIndex, offsetBy: max(0, offset), limitedBy: utf8.endIndex) ?? utf8.endIndex
        return index.utf16Offset(in: shown.text)
    }

    /// The column just past a line's last character.
    func endColumn(of shown: ShownLine) -> Int { shown.isWhole ? shown.text.utf16.count : shown.bytes.count }

    public override func draw(_ dirtyRect: NSRect) {
        style.background.setFill()
        dirtyRect.fill()
        style.gutter.setFill()
        NSRect(x: 0, y: 0, width: gutterWidth, height: bounds.height).fill()
        guard source != nil, let context = NSGraphicsContext.current?.cgContext else { return }
        let model = layoutModel
        let selection = orderedSelection
        for line in model.visibleLines(top: topLine) {
            guard let shown = shownLine(line) else { break }
            let y = model.y(ofLine: line, top: topLine)
            context.saveGState()
            context.clip(to: textArea)
            drawMatches(in: shown, y: y)
            if let selection { drawSelection(selection, in: shown, y: y) }
            context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
            context.textPosition = CGPoint(x: shown.x, y: y + ascent)
            CTLineDraw(shown.typeset, context)
            context.restoreGState()
            drawNumber(line, y: y)
        }
        style.gutter.setFill()
        NSRect(x: bounds.width - scrollerWidth, y: bounds.height - scrollerWidth, width: scrollerWidth, height: scrollerWidth).fill()
    }

    /// The selection's part of a line, to the text area's edge when it runs on past the line's end.
    private func drawSelection(_ selection: ClosedRange<LargeTextPosition>, in shown: ShownLine, y: CGFloat) {
        guard shown.line >= selection.lowerBound.line, shown.line <= selection.upperBound.line else { return }
        let from = shown.line == selection.lowerBound.line ? selection.lowerBound.column : 0
        let start = x(ofColumn: from, in: shown)
        let end =
            shown.line == selection.upperBound.line
            ? x(ofColumn: selection.upperBound.column, in: shown)
            : max(x(ofColumn: endColumn(of: shown), in: shown) + characterWidth, textArea.maxX)
        guard end > start else { return }
        style.selection.setFill()
        NSRect(x: start, y: y, width: end - start, height: lineHeight).fill()
    }

    /// The source's bytes a shown line decoded: the whole line, or the window of a long one.
    func shownBytes(_ shown: ShownLine) -> Range<Int> {
        guard !shown.isWhole else { return shown.bytes }
        let start = shown.bytes.lowerBound + shown.windowStart
        return start..<(start + shown.text.utf8.count)
    }

    /// The matches the finder gives for what a line shows, and the current match wherever it falls on it, in its own
    /// colour.
    private func drawMatches(in shown: ShownLine, y: CGFloat) {
        let bytes = shownBytes(shown)
        var found = matchFinder?(bytes) ?? []
        if let currentMatch, currentMatch.overlaps(shown.bytes), !found.contains(currentMatch) { found.append(currentMatch) }
        for match in found {
            let from = max(match.lowerBound, shown.bytes.lowerBound) - shown.bytes.lowerBound
            let to = min(match.upperBound, shown.bytes.upperBound) - shown.bytes.lowerBound
            let start = x(ofColumn: column(ofByte: from, in: shown), in: shown)
            let end = x(ofColumn: column(ofByte: to, in: shown), in: shown)
            (match == currentMatch ? style.currentMatch : style.match).setFill()
            NSRect(x: start, y: y, width: max(2, end - start), height: lineHeight).fill()
        }
    }

    /// A line's number, right-aligned in the gutter.
    private func drawNumber(_ line: Int, y: CGFloat) {
        let number = String(line + 1) as NSString
        let attributes: [NSAttributedString.Key: Any] = [.font: style.font, .foregroundColor: style.lineNumbers]
        let width = number.size(withAttributes: attributes).width
        number.draw(at: NSPoint(x: gutterWidth - LargeTextLayout.padding - width, y: y), withAttributes: attributes)
    }
}
