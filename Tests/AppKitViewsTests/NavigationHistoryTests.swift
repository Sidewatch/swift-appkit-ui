//
//  NavigationHistoryTests.swift
//  AppKitViewsTests
//
//  Two stacks, not a cursor: a new jump branches, and Back is an undo for where you chose to go.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import AppKitViews

@MainActor final class NavigationHistoryTests: XCTestCase {
    private func at(_ name: String, _ location: Int = 0) -> DocumentLocation {
        DocumentLocation(url: URL(fileURLWithPath: "/tmp/\(name).swift"), range: NSRange(location: location, length: 0))
    }

    func testAFreshHistoryGoesNowhere() {
        let h = NavigationHistory()
        XCTAssertFalse(h.canGoBack)
        XCTAssertFalse(h.canGoForward)
        XCTAssertNil(h.goBack(current: at("a")))
        XCTAssertNil(h.goForward(current: at("a")))
    }

    func testBackReturnsWhereYouCameFromAndParksTheCurrentSpot() {
        let h = NavigationHistory()
        h.recordJump(from: at("a"))
        XCTAssertTrue(h.canGoBack)
        XCTAssertEqual(h.goBack(current: at("b")), at("a"))
        XCTAssertTrue(h.canGoForward)
        XCTAssertEqual(h.goForward(current: at("a")), at("b"))
    }

    /// The whole reason for two stacks rather than a cursor: a new jump BRANCHES, so everything
    /// you had backed out of is gone rather than silently rejoinable.
    func testANewJumpClearsTheForwardPath() {
        let h = NavigationHistory()
        h.recordJump(from: at("a"))
        _ = h.goBack(current: at("b"))
        XCTAssertTrue(h.canGoForward)
        h.recordJump(from: at("c"))
        XCTAssertFalse(h.canGoForward, "you branched off the old path")
    }

    /// A tab with nothing to return to must not push a placeholder Back would land on.
    func testANilLocationRecordsNothing() {
        let h = NavigationHistory()
        h.recordJump(from: nil)
        XCTAssertFalse(h.canGoBack)
        XCTAssertTrue(h.back.isEmpty)
    }

    func testRepeatingTheSameSpotIsCoalesced() {
        let h = NavigationHistory()
        h.recordJump(from: at("a", 10))
        h.recordJump(from: at("a", 10))
        h.recordJump(from: at("a", 10))
        XCTAssertEqual(h.back.count, 1)
    }

    /// Only an exact repeat coalesces. A different position in the same file is a real jump.
    func testADifferentPositionInTheSameFileIsItsOwnEntry() {
        let h = NavigationHistory()
        h.recordJump(from: at("a", 10))
        h.recordJump(from: at("a", 400))
        XCTAssertEqual(h.back.count, 2)
    }

    func testTheStackIsCappedAndDropsTheOldestFirst() {
        let h = NavigationHistory(cap: 5)
        for i in 0..<20 { h.recordJump(from: at("f", i)) }
        XCTAssertEqual(h.back.count, 5)
        XCTAssertEqual(h.back.first, at("f", 15), "the oldest go, the newest stay")
        XCTAssertEqual(h.back.last, at("f", 19))
    }

    func testBackAndForwardWalkTheWholeChain() {
        let h = NavigationHistory()
        for i in 0..<3 { h.recordJump(from: at("f", i)) }
        var current = at("f", 3)
        for expected in [2, 1, 0] {
            let target = h.goBack(current: current)
            XCTAssertEqual(target, at("f", expected))
            current = target!
        }
        XCTAssertFalse(h.canGoBack)
        for expected in [1, 2, 3] {
            let target = h.goForward(current: current)
            XCTAssertEqual(target, at("f", expected))
            current = target!
        }
        XCTAssertFalse(h.canGoForward)
    }

    /// Stepping with no current position must not push a placeholder onto the other stack.
    func testSteppingWithNoCurrentPositionPushesNothing() {
        let h = NavigationHistory()
        h.recordJump(from: at("a"))
        _ = h.goBack(current: nil)
        XCTAssertFalse(h.canGoForward)
    }

    func testTheLastEditAnchorIsOverwrittenNotStacked() {
        let h = NavigationHistory()
        h.lastEdit = at("a", 1)
        h.lastEdit = at("b", 2)
        XCTAssertEqual(h.lastEdit, at("b", 2))
        XCTAssertTrue(h.back.isEmpty, "the anchor is not a jump")
    }

    func testClearDropsEverythingIncludingTheAnchor() {
        let h = NavigationHistory()
        h.recordJump(from: at("a"))
        _ = h.goBack(current: at("b"))
        h.lastEdit = at("c")
        h.clear()
        XCTAssertFalse(h.canGoBack)
        XCTAssertFalse(h.canGoForward)
        XCTAssertNil(h.lastEdit)
    }

    func testTwoPositionsAreEqualOnlyWhenBothFileAndRangeMatch() {
        XCTAssertEqual(at("a", 5), at("a", 5))
        XCTAssertNotEqual(at("a", 5), at("a", 6))
        XCTAssertNotEqual(at("a", 5), at("b", 5))
    }
}
