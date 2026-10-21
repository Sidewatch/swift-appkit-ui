//
//  TabStripLayoutTests.swift
//  AppKitViewsTests
//
//  Tab origins, hit-testing, the drop slot of a dragged tab, and the reveal scroll.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import AppKitViews

/// `TabStripLayout`.
final class TabStripLayoutTests: XCTestCase {
    private let strip = TabStripLayout(widths: [100, 60, 140])

    func testOriginsAndTheTabUnderAPoint() {
        XCTAssertEqual(strip.origins, [0, 100, 160])
        XCTAssertEqual(strip.origin(of: 2), 160)
        XCTAssertEqual(strip.origin(of: 9), 300, "past the end: the strip's width")
        XCTAssertEqual(strip.index(at: 0), 0)
        XCTAssertEqual(strip.index(at: 99.9), 0)
        XCTAssertEqual(strip.index(at: 100), 1, "an edge belongs to the tab it starts")
        XCTAssertEqual(strip.index(at: 299), 2)
        XCTAssertNil(strip.index(at: 300))
        XCTAssertNil(strip.index(at: -1))
    }

    func testADraggedTabDropsPastEachMidpointItsCentreCrosses() {
        // Tab 0 (100 wide) dragged right among [60, 140]: midpoints 30 and 130.
        XCTAssertEqual(strip.insertionIndex(forCenter: 30, moving: 0), 0, "on a midpoint is not past it")
        XCTAssertEqual(strip.insertionIndex(forCenter: 31, moving: 0), 1)
        XCTAssertEqual(strip.insertionIndex(forCenter: 131, moving: 0), 2)
        // Tab 2 dragged left among [100, 60]: midpoints 50 and 130.
        XCTAssertEqual(strip.insertionIndex(forCenter: 40, moving: 2), 0)
        XCTAssertEqual(strip.insertionIndex(forCenter: 120, moving: 2), 1)
    }

    func testTheOthersCloseUpAroundTheSlotWhileATabIsDragged() {
        XCTAssertEqual(strip.origins(moving: 0, to: 1, draggedOrigin: 75), [75, 0, 160])
        XCTAssertEqual(strip.origins(moving: 2, to: 0, draggedOrigin: 10), [140, 240, 10])
        XCTAssertEqual(strip.origins(moving: 7, to: 0, draggedOrigin: 10), strip.origins, "no such tab: at rest")
    }

    func testRevealingATabScrollsAsLittleAsPossibleAndStaysInRange() {
        XCTAssertEqual(strip.scrollOffset(revealing: 2, from: 0, visibleWidth: 200), 100, "right edge into view")
        XCTAssertEqual(strip.scrollOffset(revealing: 0, from: 100, visibleWidth: 200), 0, "left edge into view")
        XCTAssertEqual(strip.scrollOffset(revealing: 1, from: 50, visibleWidth: 200), 50, "already shown: no move")
        XCTAssertEqual(strip.scrollOffset(revealing: 2, from: 0, visibleWidth: 200, trailing: 30), 100)
        XCTAssertEqual(strip.scrollOffset(revealing: 9, from: 500, visibleWidth: 200, trailing: 30), 130, "out of range: clamped")
    }
}
