//
//  LargeTextView+Selection.swift
//  AppKitViews
//
//  LargeTextView: selecting with the mouse and the keyboard, and copying what is selected.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

extension LargeTextView: NSMenuItemValidation {
    /// The selection's two ends in order, or nil when nothing is selected.
    public var orderedSelection: ClosedRange<LargeTextPosition>? {
        guard let anchor, let head, anchor != head else { return nil }
        return min(anchor, head)...max(anchor, head)
    }

    /// The position under `point`, in the view's coordinates, clamped to the lines there are.
    func position(at point: NSPoint) -> LargeTextPosition {
        let model = layoutModel
        let line = min(max(0, model.line(atY: point.y, top: topLine)), max(0, model.lineCount - 1))
        guard let shown = shownLine(line) else { return LargeTextPosition(line: line, column: 0) }
        let index = CTLineGetStringIndexForPosition(shown.typeset, CGPoint(x: point.x - shown.x, y: 0))
        let utf16 = shown.text.utf16
        let clamped = index == kCFNotFound ? 0 : max(0, min(index, utf16.count))
        guard !shown.isWhole else { return LargeTextPosition(line: line, column: clamped) }
        let at = utf16.index(utf16.startIndex, offsetBy: clamped)
        let bytes = shown.text.utf8.distance(from: shown.text.utf8.startIndex, to: at)
        return LargeTextPosition(line: line, column: shown.windowStart + bytes)
    }

    public override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)
        guard point.y < textArea.maxY, point.x < textArea.maxX else { return }
        let position = position(at: point)
        if event.clickCount >= 3, let shown = shownLine(position.line) {
            anchor = LargeTextPosition(line: position.line, column: 0)
            head = LargeTextPosition(line: position.line, column: endColumn(of: shown))
        } else if event.modifierFlags.contains(.shift), anchor != nil {
            head = position
        } else {
            anchor = position
            head = position
        }
        selectionChanged()
    }

    public override func mouseDragged(with event: NSEvent) {
        guard anchor != nil else { return }
        let point = convert(event.locationInWindow, from: nil)
        // Past an edge the text scrolls under the pointer, a line or a few columns per event.
        if point.y < textArea.minY { scroll(toTop: topLine - 1) } else if point.y > textArea.maxY { scroll(toTop: topLine + 1) }
        if point.x < textArea.minX {
            scroll(toLeft: leftX - characterWidth * 2)
        } else if point.x > textArea.maxX {
            scroll(toLeft: leftX + characterWidth * 2)
        }
        let inside = NSPoint(x: min(max(point.x, textArea.minX), textArea.maxX), y: min(max(point.y, textArea.minY), textArea.maxY - 1))
        head = position(at: inside)
        selectionChanged()
    }

    /// Redraws and tells the host.
    func selectionChanged() {
        needsDisplay = true
        onSelectionChange?(orderedSelection)
    }

    /// Selects from `from` to `to`, in either order, and scrolls `to` into view.
    public func select(from: LargeTextPosition, to: LargeTextPosition) {
        anchor = from
        head = to
        scroll(toTop: layoutModel.topRevealing(to.line, from: topLine))
        selectionChanged()
    }

    /// Selects 0-based `line` whole (clamped to the lines there are) and brings it to the middle of the view. Not
    /// `selectLine(_:)`: that is NSResponder's own action, which a call from another module would reach instead.
    public func goToLine(_ line: Int) {
        guard let source, source.lineCount > 0 else { return }
        let target = min(max(0, line), source.lineCount - 1)
        scrollToLine(target)
        guard let shown = shownLine(target) else { return }
        anchor = LargeTextPosition(line: target, column: 0)
        head = LargeTextPosition(line: target, column: endColumn(of: shown))
        selectionChanged()
    }

    public override func selectAll(_ sender: Any?) {
        guard let source, source.lineCount > 0, let last = shownLine(source.lineCount - 1) else { return }
        anchor = LargeTextPosition(line: 0, column: 0)
        head = LargeTextPosition(line: last.line, column: endColumn(of: last))
        selectionChanged()
    }

    /// The selected text: nil when nothing is selected, or when the selection spans more than ``copyLimit`` bytes
    /// (``onCopyRefused`` is told).
    public func selectedText() -> String? {
        guard let source, let range = orderedSelection, let first = source.byteRange(ofLine: range.lowerBound.line),
            let last = source.byteRange(ofLine: range.upperBound.line)
        else { return nil }
        let span = last.upperBound - first.lowerBound
        guard span <= Self.copyLimit else {
            onCopyRefused?(span)
            return nil
        }
        var out = ""
        for line in range.lowerBound.line...range.upperBound.line {
            guard let bytes = source.byteRange(ofLine: line) else { break }
            let from = line == range.lowerBound.line ? range.lowerBound.column : 0
            let to = line == range.upperBound.line ? range.upperBound.column : Int.max
            out += slice(of: bytes, from: from, to: to)
            if line < range.upperBound.line { out += "\n" }
        }
        return out
    }

    /// Columns `from..<to` of the line whose bytes are `bytes`.
    private func slice(of bytes: Range<Int>, from: Int, to: Int) -> String {
        guard let source else { return "" }
        guard bytes.count <= Self.wholeLineLimit else {
            let start = bytes.lowerBound + min(max(0, from), bytes.count)
            return source.text(in: start..<(bytes.lowerBound + min(max(from, to), bytes.count)))
        }
        let units = Array(source.text(in: bytes).utf16)
        let start = min(max(0, from), units.count)
        return String(decoding: units[start..<min(max(start, to), units.count)], as: UTF16.self)
    }

    /// Copies the selection; a selection too large to copy is refused (``onCopyRefused``).
    @objc public func copy(_ sender: Any?) {
        guard let text = selectedText() else { return }
        _ = NSPasteboard.general.copy(text)
    }

    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(copy(_:)): return orderedSelection != nil
        case #selector(selectAll(_:)): return source != nil
        default: return true
        }
    }
}
