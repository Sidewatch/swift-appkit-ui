//
//  LargeTextLayoutTests.swift
//  AppKitViewsTests
//
//  The large text view's arithmetic: how far it scrolls, which lines show, what the scrollers say.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest

@testable import AppKitViews

final class LargeTextLayoutTests: XCTestCase {
    /// 100 lines of 10 points in a 50-point viewport: five lines a page.
    private let layout = LargeTextLayout(
        viewport: CGSize(width: 200, height: 50), lineHeight: 10, characterWidth: 5, lineCount: 100, longestLine: 80)

    func testTheLastLineCanRestAtTheBottomAndNoFurther() {
        XCTAssertEqual(layout.linesPerPage, 5)
        XCTAssertEqual(layout.maxTopLine, 95)
        XCTAssertEqual(layout.clampedTop(-3), 0)
        XCTAssertEqual(layout.clampedTop(500), 95)
        var short = layout
        short.lineCount = 3
        XCTAssertEqual(short.maxTopLine, 0, "everything fits")
    }

    func testTheVisibleLinesIncludeOneCutByEitherEdge() {
        XCTAssertEqual(layout.visibleLines(top: 0), 0..<5)
        XCTAssertEqual(layout.visibleLines(top: 2.5), 2..<8)
        XCTAssertEqual(layout.visibleLines(top: 95), 95..<100)
    }

    func testLinesAndPointsMapBothWays() {
        XCTAssertEqual(layout.y(ofLine: 12, top: 10), 20)
        XCTAssertEqual(layout.line(atY: 25, top: 10), 12)
        XCTAssertEqual(layout.line(atY: 0, top: 10.5), 10)
    }

    func testRevealingMovesAsLittleAsItCanAndCentringCentres() {
        XCTAssertEqual(layout.topRevealing(12, from: 10), 10, "already in view")
        XCTAssertEqual(layout.topRevealing(20, from: 10), 16, "just in at the bottom")
        XCTAssertEqual(layout.topRevealing(4, from: 10), 4, "just in at the top")
        XCTAssertEqual(layout.topCentring(50), 48)
        XCTAssertEqual(layout.topCentring(1), 0, "clamped")
    }

    func testTheScrollerStandsForTheTopLine() {
        let knob = layout.scroller(top: 47.5)
        XCTAssertEqual(knob.proportion, 0.05, accuracy: 0.0001)
        XCTAssertEqual(knob.value, 0.5, accuracy: 0.0001)
        XCTAssertEqual(layout.top(forScrollerValue: 0.5), 47.5)
        XCTAssertEqual(layout.top(forScrollerValue: 7), 95, "clamped")
    }

    func testTheHorizontalExtentAndTheGutter() {
        XCTAssertEqual(layout.maxLeftX, 80 * 5 + 16 - 200)
        XCTAssertEqual(layout.clampedLeft(1000), 216)
        XCTAssertEqual(LargeTextLayout.gutterWidth(lineCount: 9_791_734, characterWidth: 5), 7 * 5 + 16)
    }
}
