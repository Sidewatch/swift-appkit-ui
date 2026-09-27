//
//  CardGridViewTests.swift
//  AppKitViewsTests
//
//  The column count reflows with the width, and the height changes only at those breakpoints.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import AppKitViews

@MainActor final class CardGridViewTests: XCTestCase {
    private func grid(_ count: Int, width: CGFloat) -> CardGridView {
        let g = CardGridView(cards: (0..<count).map { _ in NSView() })
        g.frame = NSRect(x: 0, y: 0, width: width, height: 400)
        g.layoutSubtreeIfNeeded()
        return g
    }

    func testAWideGridPutsEveryCardOnOneRow() {
        let g = grid(4, width: 800)
        XCTAssertEqual(g.gridShape(for: 800).cols, 4)
        XCTAssertEqual(g.gridShape(for: 800).rows, 1)
    }

    func testANarrowGridStacksToASingleColumn() {
        let g = grid(4, width: 120)
        XCTAssertEqual(g.gridShape(for: 120).cols, 1)
        XCTAssertEqual(g.gridShape(for: 120).rows, 4)
    }

    /// Never more columns than cards, or two cards in a wide panel would each get a quarter.
    func testTheColumnCountNeverExceedsTheCardCount() {
        let g = grid(2, width: 2000)
        XCTAssertEqual(g.gridShape(for: 2000).cols, 2)
    }

    func testTheColumnCountFallsAsTheWidthDoes() {
        let g = grid(6, width: 800)
        let counts = [800.0, 600.0, 400.0, 250.0, 120.0].map { g.gridShape(for: $0).cols }
        XCTAssertEqual(counts, counts.sorted(by: >), "got \(counts)")
        XCTAssertEqual(counts.last, 1)
    }

    func testEveryCardIsPlacedAndCardsShareTheRowExactly() {
        let g = grid(4, width: 800)
        let frames = g.cards.map(\.frame)
        XCTAssertEqual(Set(frames.map(\.minY)).count, 1, "one row at this width")
        let widths = Set(frames.map(\.width))
        XCTAssertEqual(widths.count, 1, "equal shares")
        for f in frames { XCTAssertEqual(f.height, g.cardHeight) }
        let spread = frames.map(\.minX).sorted()
        XCTAssertEqual(spread[1] - spread[0], frames[0].width + g.spacing, accuracy: 1)
    }

    func testASecondRowSitsOneCardHeightPlusSpacingBelow() {
        let g = grid(4, width: 250)
        let rows = Set(g.cards.map(\.frame.minY)).sorted()
        XCTAssertGreaterThan(rows.count, 1)
        XCTAssertEqual(rows[1] - rows[0], g.cardHeight + g.spacing, accuracy: 0.5)
    }

    func testTheHeightIsTheRowCountNotTheCardCount() {
        let g = grid(4, width: 800)
        XCTAssertEqual(g.height(rows: 1), g.cardHeight)
        XCTAssertEqual(g.height(rows: 3), g.cardHeight * 3 + g.spacing * 2)
        XCTAssertEqual(g.intrinsicContentSize.height, g.height(rows: 1))
    }

    /// The height must be a function of the width, or the panel clips a stacked grid.
    func testTheIntrinsicHeightGrowsWhenTheGridStacks() {
        let g = grid(4, width: 800)
        let wide = g.intrinsicContentSize.height
        g.setFrameSize(NSSize(width: 120, height: 400))
        XCTAssertGreaterThan(g.intrinsicContentSize.height, wide)
    }

    /// The whole reason the height is reported from `setFrameSize` and only at column
    /// boundaries: a view that reports a new height every pixel never converges during a
    /// continuous resize, and AppKit aborts the layout pass.
    func testTheHeightChangesAtAFewBreakpointsNotEveryPixel() {
        let g = grid(6, width: 800)
        var heights: [CGFloat] = []
        for w in stride(from: 800.0, through: 120.0, by: -1.0) {
            g.setFrameSize(NSSize(width: w, height: 400))
            heights.append(g.intrinsicContentSize.height)
        }
        let changes = zip(heights, heights.dropFirst()).filter { $0 != $1 }.count
        XCTAssertLessThanOrEqual(changes, 8, "height changed \(changes) times across 680 pixels")
        XCTAssertGreaterThan(changes, 0, "it must change at SOME width, or it is not reflowing")
    }

    func testAnEmptyGridIsHarmless() {
        let g = grid(0, width: 400)
        XCTAssertEqual(g.gridShape(for: 400).cols, 1)
        XCTAssertEqual(g.intrinsicContentSize.height, g.cardHeight)
        g.setFrameSize(NSSize(width: 100, height: 100))
    }

    func testAZeroWidthReportsAFallbackRatherThanDividingByIt() {
        let g = CardGridView(cards: [NSView(), NSView()])
        XCTAssertEqual(g.intrinsicContentSize.height, g.cardHeight)
        g.layoutSubtreeIfNeeded()
    }

    func testTheMinimumCardWidthDecidesTheBreakpoints() {
        let narrow = CardGridView(cards: (0..<4).map { _ in NSView() }, minCardWidth: 50)
        let wide = CardGridView(cards: (0..<4).map { _ in NSView() }, minCardWidth: 200)
        XCTAssertGreaterThan(narrow.gridShape(for: 420).cols, wide.gridShape(for: 420).cols)
    }

    /// Cards are framed, never constrained, which is what keeps the layout a pure function.
    func testCardsAreFrameDriven() {
        let g = grid(3, width: 600)
        for c in g.cards { XCTAssertTrue(c.translatesAutoresizingMaskIntoConstraints) }
        XCTAssertFalse(g.translatesAutoresizingMaskIntoConstraints, "the grid itself is constrained by its host")
    }
}
