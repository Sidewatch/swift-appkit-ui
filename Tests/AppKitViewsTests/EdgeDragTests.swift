//
//  EdgeDragTests.swift
//  AppKitViewsTests
//
//  A dragged edge grows its pane the right way, within its range.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import AppKitViews

/// `EdgeDrag.size(at:)`.
final class EdgeDragTests: XCTestCase {
    private func drag(_ grows: EdgeDragDirection) -> EdgeDrag {
        EdgeDrag(from: CGPoint(x: 100, y: 100), size: 200, grows: grows, range: 50...400)
    }

    func testEachDirectionGrowsWithThePointerMovingThatWay() {
        XCTAssertEqual(drag(.up).size(at: CGPoint(x: 100, y: 130)), 230, "y runs upward")
        XCTAssertEqual(drag(.down).size(at: CGPoint(x: 100, y: 130)), 170)
        XCTAssertEqual(drag(.left).size(at: CGPoint(x: 70, y: 100)), 230)
        XCTAssertEqual(drag(.right).size(at: CGPoint(x: 70, y: 100)), 170)
        XCTAssertEqual(drag(.up).size(at: CGPoint(x: 500, y: 100)), 200, "the other axis does nothing")
    }

    func testTheSizeStaysInItsRange() {
        XCTAssertEqual(drag(.up).size(at: CGPoint(x: 100, y: 1000)), 400)
        XCTAssertEqual(drag(.up).size(at: CGPoint(x: 100, y: -1000)), 50)
    }
}
