//
//  LargeTextViewTests.swift
//  AppKitViewsTests
//
//  The large text view over an in-memory source: drawn, scrolled, selected, copied and searched, a long line read
//  as a window, a growing source followed.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import XCTest

@testable import AppKitViews

/// Lines held in memory as UTF-8, the way a file holds them.
private final class LinesSource: LargeTextSource {
    var bytes: [UInt8]
    var starts: [Int]
    /// When set, every range is made this much longer than the bytes there are (a selection past the copy limit).
    var claimedLength: Int?

    init(_ lines: [String]) {
        bytes = Array(lines.joined(separator: "\n").utf8)
        starts = [0]
        for (i, byte) in bytes.enumerated() where byte == 0x0A { starts.append(i + 1) }
    }

    func append(_ lines: [String]) {
        bytes += Array(("\n" + lines.joined(separator: "\n")).utf8)
        starts = [0]
        for (i, byte) in bytes.enumerated() where byte == 0x0A { starts.append(i + 1) }
    }

    var lineCount: Int { starts.count }
    var longestLineBytes: Int { (0..<starts.count).compactMap { byteRange(ofLine: $0)?.count }.max() ?? 0 }
    func byteRange(ofLine line: Int) -> Range<Int>? {
        guard line >= 0, line < starts.count else { return nil }
        let end = line + 1 < starts.count ? starts[line + 1] - 1 : bytes.count
        return starts[line]..<(starts[line] + (claimedLength ?? (end - starts[line])))
    }
    func text(in range: Range<Int>) -> String {
        String(decoding: bytes[min(range.lowerBound, bytes.count)..<min(range.upperBound, bytes.count)], as: UTF8.self)
    }
    func characterStart(atOrBefore offset: Int) -> Int {
        var at = min(offset, bytes.count)
        while at > 0, at < bytes.count, bytes[at] & 0xC0 == 0x80 { at -= 1 }
        return at
    }
    func line(containingByte offset: Int) -> Int { (starts.lastIndex { $0 <= offset } ?? 0) }
}

@MainActor final class LargeTextViewTests: XCTestCase {
    private func view(_ source: LinesSource, size: NSSize = NSSize(width: 600, height: 300)) -> LargeTextView {
        let view = LargeTextView(frame: NSRect(origin: .zero, size: size))
        view.style = LargeTextStyle(
            font: .monospacedSystemFont(ofSize: 12, weight: .regular), text: .black, background: .white, lineNumbers: .gray,
            gutter: .white, selection: .systemBlue, match: .systemYellow, currentMatch: .systemOrange)
        view.source = source
        return view
    }

    private func numbered(_ count: Int) -> LinesSource { LinesSource((1...count).map { "line \($0)" }) }

    func testAPointMapsToTheColumnUnderIt() throws {
        let source = LinesSource(["0123456789", "abcdefghij"])
        let view = view(source)
        let shown = try XCTUnwrap(view.shownLine(1))
        let x = view.x(ofColumn: 4, in: shown) + 1
        XCTAssertEqual(view.position(at: NSPoint(x: x, y: view.lineHeight * 1.5)), LargeTextPosition(line: 1, column: 4))
        XCTAssertEqual(view.position(at: NSPoint(x: x, y: 10_000)).line, 1, "past the last line: the last line")
    }

    func testASelectionAcrossLinesCopiesItsTextWithTheBreaks() {
        let view = view(LinesSource(["alpha", "bravo", "charlie"]))
        view.select(from: LargeTextPosition(line: 0, column: 2), to: LargeTextPosition(line: 2, column: 4))
        XCTAssertEqual(view.selectedText(), "pha\nbravo\nchar")
        view.select(from: LargeTextPosition(line: 2, column: 4), to: LargeTextPosition(line: 0, column: 2))
        XCTAssertEqual(view.selectedText(), "pha\nbravo\nchar", "either direction")
        view.selectAll(nil)
        XCTAssertEqual(view.selectedText(), "alpha\nbravo\ncharlie")
    }

    /// A line past the whole-line limit is read only as the window on screen, and selected and copied by byte.
    func testALongLineIsReadAsAWindow() throws {
        let long = String((0..<40_000).map { Character(UnicodeScalar(UInt8(97 + $0 % 26))) })
        let view = view(LinesSource(["short", long]))
        view.scroll(toLeft: 20_000 * view.characterWidth)
        let shown = try XCTUnwrap(view.shownLine(1))
        XCTAssertFalse(shown.isWhole)
        XCTAssertLessThan(shown.text.utf8.count, 1_000, "a screen's width, not 40,000 characters")
        let column = view.position(at: NSPoint(x: view.textArea.minX + 1, y: view.lineHeight * 1.5)).column
        XCTAssertEqual(Double(column), 20_000, accuracy: 3)
        view.select(from: LargeTextPosition(line: 1, column: 20_000), to: LargeTextPosition(line: 1, column: 20_010))
        let start = long.index(long.startIndex, offsetBy: 20_000)
        XCTAssertEqual(view.selectedText(), String(long[start..<long.index(start, offsetBy: 10)]))
    }

    func testASelectionPastTheCopyLimitIsRefused() {
        let source = LinesSource(["a", "b"])
        source.claimedLength = LargeTextView.copyLimit
        let view = view(source)
        var refused: Int?
        view.onCopyRefused = { refused = $0 }
        view.select(from: LargeTextPosition(line: 0, column: 0), to: LargeTextPosition(line: 1, column: 1))
        XCTAssertNil(view.selectedText())
        XCTAssertNotNil(refused)
    }

    func testAMatchIsRevealedAndSelected() throws {
        let source = numbered(1_000)
        let view = view(source)
        let offset = try XCTUnwrap(source.byteRange(ofLine: 499)).lowerBound + 5  // "line 500": the "500"
        view.showMatch(offset..<(offset + 3))
        XCTAssertTrue(view.layoutModel.visibleLines(top: view.topLine).contains(499))
        XCTAssertEqual(view.orderedSelection, LargeTextPosition(line: 499, column: 5)...LargeTextPosition(line: 499, column: 8))
        XCTAssertEqual(view.selectedText(), "500")
    }

    /// The finder is asked for what each line on screen shows, and no more; its matches are drawn in the match colour
    /// and the current one in its own.
    func testTheMatchesOnScreenAreAskedForAsItDraws() throws {
        let source = LinesSource((1...1_000).map { "line \($0) x y" })
        let view = view(source)
        var asked: [Range<Int>] = []
        view.matchFinder = { range in
            asked.append(range)
            let text = source.text(in: range)
            return text.utf8.firstIndex(of: 0x20).map { [range.lowerBound + text.utf8.distance(from: text.utf8.startIndex, to: $0)] }?
                .map { $0..<($0 + 1) } ?? []
        }
        let rep = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: rep)
        let visible = view.layoutModel.visibleLines(top: view.topLine)
        XCTAssertEqual(asked, visible.compactMap { source.byteRange(ofLine: $0) }, "each line on screen, whole, and nothing else")
        func colour(line: Int, byte: Int) throws -> NSColor {
            let shown = try XCTUnwrap(view.shownLine(line))
            let x = view.x(ofColumn: byte, in: shown) + view.characterWidth / 2
            let y = view.layoutModel.y(ofLine: line, top: view.topLine) + view.lineHeight / 2
            let scale = CGFloat(rep.pixelsWide) / view.bounds.width
            return try XCTUnwrap(rep.colorAt(x: Int(x * scale), y: Int(y * scale))?.usingColorSpace(.sRGB))
        }
        func near(_ a: NSColor, _ b: NSColor) -> Bool {
            guard let b = b.usingColorSpace(.sRGB) else { return false }
            return abs(a.redComponent - b.redComponent) < 0.1 && abs(a.greenComponent - b.greenComponent) < 0.1
                && abs(a.blueComponent - b.blueComponent) < 0.1
        }
        XCTAssertTrue(near(try colour(line: 0, byte: 4), view.style.match), "the space after \"line\" is marked")
        XCTAssertTrue(near(try colour(line: 0, byte: 2), view.style.background), "the rest is not")
        let first = try XCTUnwrap(source.byteRange(ofLine: 1)).lowerBound + 4
        view.showMatch(first..<(first + 1))
        view.cacheDisplay(in: view.bounds, to: rep)
        XCTAssertTrue(near(try colour(line: 1, byte: 4), view.style.selection), "moved to: selected")
        view.select(from: LargeTextPosition(line: 0, column: 0), to: LargeTextPosition(line: 0, column: 0))
        view.cacheDisplay(in: view.bounds, to: rep)
        XCTAssertTrue(near(try colour(line: 1, byte: 4), view.style.currentMatch), "the caret elsewhere: the current one in its own colour")
    }

    /// A line too long to read whole asks the finder for the stretch on screen only, never the whole line.
    func testALongLineAsksTheFinderOnlyForTheStretchOnScreen() throws {
        let long = String(repeating: "abcdefghij", count: 4_000)
        let source = LinesSource(["short", long])
        let view = view(source)
        view.scroll(toLeft: 20_000 * view.characterWidth)
        var asked: [Range<Int>] = []
        view.matchFinder = { range in
            asked.append(range)
            return []
        }
        let rep = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: rep)
        let lineStart = try XCTUnwrap(source.byteRange(ofLine: 1)).lowerBound
        let window = try XCTUnwrap(asked.first { $0.lowerBound >= lineStart })
        XCTAssertLessThan(window.count, 1_000, "a screen's width, not 40,000 bytes")
        XCTAssertEqual(Double(window.lowerBound - lineStart), 20_000, accuracy: 3)
    }

    /// Where a search moves on from: the selection, or a caret, as bytes, through characters of every width.
    func testTheSelectionIsReadAsBytes() {
        let view = view(LinesSource(["héllo", "wörld"]))
        XCTAssertNil(view.selectionBytes)
        view.select(from: LargeTextPosition(line: 1, column: 1), to: LargeTextPosition(line: 1, column: 3))
        XCTAssertEqual(view.selectionBytes, 8..<11)
        view.select(from: LargeTextPosition(line: 0, column: 2), to: LargeTextPosition(line: 0, column: 2))
        XCTAssertEqual(view.selectionBytes, 3..<3, "a caret")
    }

    func testGoingToALineSelectsItInTheMiddle() {
        let view = view(numbered(1_000))
        view.goToLine(499)
        XCTAssertEqual(view.selectedText(), "line 500")
        let visible = view.layoutModel.visibleLines(top: view.topLine)
        XCTAssertTrue(visible.contains(499))
        XCTAssertEqual(Double(499 - visible.lowerBound), view.layoutModel.linesPerPage / 2, accuracy: 1.5, "about the middle")
        view.goToLine(5_000)
        XCTAssertEqual(view.selectedText(), "line 1000", "clamped to the last line")
    }

    /// Resting at the last line, the view follows a growing source; anywhere else it stays put.
    func testAGrowingSourceIsFollowedOnlyFromTheBottom() {
        let source = numbered(100)
        let view = view(source)
        view.scrollToEndOfDocument(nil)
        source.append(["more", "and more"])
        view.sourceDidGrow()
        XCTAssertEqual(view.topLine, view.layoutModel.maxTopLine)
        view.scroll(toTop: 10)
        source.append(["still more"])
        view.sourceDidGrow()
        XCTAssertEqual(view.topLine, 10)
    }

    func testTheKeysScroll() {
        let view = view(numbered(1_000))
        view.pageDown(nil)
        XCTAssertEqual(view.topLine, view.layoutModel.linesPerPage - 1, accuracy: 0.001)
        view.moveToEndOfDocument(nil)
        XCTAssertEqual(view.topLine, view.layoutModel.maxTopLine)
        view.moveToBeginningOfDocument(nil)
        XCTAssertEqual(view.topLine, 0)
    }

    /// Drawn and read back: the first line's text in the text area, its number in the gutter, nothing in the margin
    /// after a short line.
    func testTheTextAndTheNumbersAreDrawn() throws {
        let view = view(LinesSource(["WWWWWWWW", "x"]))
        let rep = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: rep)
        func inked(_ rect: NSRect) -> Bool {
            let scale = CGFloat(rep.pixelsWide) / view.bounds.width
            for y in stride(from: rect.minY, to: rect.maxY, by: 1) {
                for x in stride(from: rect.minX, to: rect.maxX, by: 1) {
                    guard let color = rep.colorAt(x: Int(x * scale), y: Int(y * scale))?.usingColorSpace(.sRGB) else { continue }
                    if color.brightnessComponent < 0.5 { return true }
                }
            }
            return false
        }
        let textLine = NSRect(x: view.textArea.minX, y: 0, width: view.characterWidth * 8 + 16, height: view.lineHeight)
        XCTAssertTrue(inked(textLine), "the first line's text")
        XCTAssertTrue(inked(NSRect(x: 0, y: 0, width: view.gutterWidth, height: view.lineHeight)), "its number")
        XCTAssertFalse(inked(NSRect(x: view.textArea.minX + 200, y: 0, width: 100, height: view.lineHeight)), "nothing past its end")
    }
}
