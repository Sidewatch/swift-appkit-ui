//
//  TabSelectionTests.swift
//  AppKitViewsTests
//
//  The selected tab through moves and closes, and the most-recently-used order.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import AppKitViews

/// `TabSelection` and `RecentOrder`.
final class TabSelectionTests: XCTestCase {
    func testAMoveKeepsTheSameTabSelected() {
        XCTAssertEqual(TabSelection.afterMove(from: 2, to: 0, selected: 2), 0, "the selected tab itself moved")
        XCTAssertEqual(TabSelection.afterMove(from: 0, to: 3, selected: 2), 1, "a tab from before it moved past it")
        XCTAssertEqual(TabSelection.afterMove(from: 4, to: 1, selected: 2), 3, "a tab from after it moved before it")
        XCTAssertEqual(TabSelection.afterMove(from: 4, to: 3, selected: 1), 1, "a move elsewhere")
    }

    func testClosingAnotherTabKeepsTheSameTabSelected() {
        XCTAssertEqual(TabSelection.afterClosing(0, selected: 2, remaining: 3, successor: .rightNeighbour), 1, "a tab before it")
        XCTAssertEqual(TabSelection.afterClosing(3, selected: 1, remaining: 3, successor: .rightNeighbour), 1, "a tab after it")
    }

    func testClosingTheSelectedTabHandsOverByTheRule() {
        XCTAssertEqual(
            TabSelection.afterClosing(1, selected: 1, remaining: 3, successor: .rightNeighbour), 1, "the right neighbour slides in")
        XCTAssertEqual(TabSelection.afterClosing(3, selected: 3, remaining: 3, successor: .rightNeighbour), 2, "the last tab: the new last")
        XCTAssertEqual(TabSelection.afterClosing(1, selected: 1, remaining: 3, successor: .recentElseLeft(2)), 2, "the most recent")
        XCTAssertEqual(TabSelection.afterClosing(1, selected: 1, remaining: 3, successor: .recentElseLeft(nil)), 0, "else the left")
        XCTAssertEqual(TabSelection.afterClosing(0, selected: 0, remaining: 2, successor: .recentElseLeft(nil)), 0, "no left: the first")
        XCTAssertNil(TabSelection.afterClosing(0, selected: 0, remaining: 0, successor: .rightNeighbour), "none left")
    }

    func testRecentOrderTracksUseAndForgetsWhatCloses() {
        var order = RecentOrder<String>()
        for id in ["a", "b", "c", "b"] { order.touch(id) }
        XCTAssertEqual(order.ids, ["b", "c", "a"])
        XCTAssertEqual(order.ordered(["a", "b", "c", "d"]), ["b", "c", "a", "d"], "never-used last, in order")
        order.remove("b")
        XCTAssertEqual(order.mostRecent(among: ["a", "c"]), "c")
        XCTAssertNil(order.mostRecent(among: ["d"]))
        XCTAssertEqual(order.ordered(["a", "d"]), ["a", "d"], "only what is present")
        order.keep(only: ["c"])
        XCTAssertEqual(order.ids, ["c"], "what no longer exists is forgotten")
    }
}
