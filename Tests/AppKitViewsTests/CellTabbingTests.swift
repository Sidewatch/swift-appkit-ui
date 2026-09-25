//
//  CellTabbingTests.swift
//  AppKitViewsTests
//
//  Tab and ⇧Tab walking a table's editable cells, and stopping at the ends.
//
//  Created by David Sherlock on 9/26/26.
//

import XCTest
import AppKit
@testable import AppKitViews

/// A table of `rows` × two editable fields (tags 1 and 2), in reading order.
@MainActor final class TwoColumnTable: NSView, CellTabbing {
    var rows: Int
    private(set) var opened: [CellPosition] = []
    init(rows: Int) {
        self.rows = rows
        super.init(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
    }
    required init?(coder: NSCoder) { fatalError() }

    var editableCells: [CellPosition] {
        (0..<rows).flatMap { row in [CellPosition(row: row, tag: 1), CellPosition(row: row, tag: 2)] }
    }
    func beginEditing(_ position: CellPosition) { opened.append(position) }
}

@MainActor final class CellTabbingTests: XCTestCase {
    func testTabWalksAcrossTheRowThenOnToTheNext() {
        let table = TwoColumnTable(rows: 3)
        XCTAssertEqual(table.cell(after: CellPosition(row: 0, tag: 1), forward: true), CellPosition(row: 0, tag: 2))
        XCTAssertEqual(table.cell(after: CellPosition(row: 0, tag: 2), forward: true), CellPosition(row: 1, tag: 1))
    }

    func testShiftTabWalksBackTheSameWay() {
        let table = TwoColumnTable(rows: 3)
        XCTAssertEqual(table.cell(after: CellPosition(row: 1, tag: 1), forward: false), CellPosition(row: 0, tag: 2))
        XCTAssertEqual(table.cell(after: CellPosition(row: 0, tag: 2), forward: false), CellPosition(row: 0, tag: 1))
    }

    /// Stopping rather than wrapping is the point: a held Tab must not silently start over at
    /// the top, which reads as the keyboard jumping somewhere at random.
    func testTabStopsAtBothEndsRatherThanWrapping() {
        let table = TwoColumnTable(rows: 3)
        XCTAssertNil(table.cell(after: CellPosition(row: 2, tag: 2), forward: true), "no wrap at the end")
        XCTAssertNil(table.cell(after: CellPosition(row: 0, tag: 1), forward: false), "no wrap at the start")
    }

    /// A position the table no longer shows has no neighbour, so a stale move does nothing
    /// rather than landing somewhere arbitrary.
    func testAPositionTheTableDoesNotHoldHasNoNeighbour() {
        let table = TwoColumnTable(rows: 2)
        XCTAssertNil(table.cell(after: CellPosition(row: 9, tag: 1), forward: true))
        XCTAssertNil(table.cell(after: CellPosition(row: 0, tag: 7), forward: true))
    }

    func testASingleCellTableHasNowhereToGo() {
        final class OneCell: NSView, CellTabbing {
            var editableCells: [CellPosition] { [CellPosition(row: 0, tag: 1)] }
            func beginEditing(_ position: CellPosition) {}
        }
        let table = OneCell()
        XCTAssertNil(table.cell(after: CellPosition(row: 0, tag: 1), forward: true))
        XCTAssertNil(table.cell(after: CellPosition(row: 0, tag: 1), forward: false))
    }

    /// The retry is what survives a table that rebuilds its rows on commit. With no window
    /// there is no field editor, so `isEditing` is false and both attempts are spent.
    func testBeginEditingWhenReadyRetriesWhileTheCellHasNotTakenTheKeyboard() {
        let table = TwoColumnTable(rows: 2)
        let target = CellPosition(row: 1, tag: 2)
        table.beginEditingWhenReady(target)
        let done = expectation(description: "retries drain")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { done.fulfill() }
        wait(for: [done], timeout: 2)
        XCTAssertEqual(table.opened, [target, target], "one attempt plus one retry")
    }

    /// And it gives up rather than retrying for ever.
    func testBeginEditingWhenReadyStopsAfterItsAttempts() {
        let table = TwoColumnTable(rows: 2)
        table.beginEditingWhenReady(CellPosition(row: 0, tag: 1), attemptsLeft: 1)
        let done = expectation(description: "single attempt")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { done.fulfill() }
        wait(for: [done], timeout: 2)
        XCTAssertEqual(table.opened.count, 1)
    }

    func testReadingOrderIsLeftToRightThenTopToBottom() {
        let table = TwoColumnTable(rows: 2)
        XCTAssertEqual(table.editableCells, [
            CellPosition(row: 0, tag: 1), CellPosition(row: 0, tag: 2),
            CellPosition(row: 1, tag: 1), CellPosition(row: 1, tag: 2),
        ])
    }
}
