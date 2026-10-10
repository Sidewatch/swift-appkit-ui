//
//  ReusableViewTests.swift
//  AppKitViewsTests
//
//  A scrolled or reloaded list keeps only the row views and cells it is showing.
//
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import AppKitViews

@MainActor final class ReusableViewTests: XCTestCase {
    /// A flat list whose delegate returns its row views through `reusableView`, or (`plain`)
    /// builds one per call without it, and remembers each it built weakly so a test can count
    /// the survivors. Every fifth row is a second kind of row view.
    @MainActor private final class RowSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        final class Row: NSTableRowView {}
        final class OtherRow: NSTableRowView {}
        struct Weak { weak var row: NSTableRowView? }

        let plain: Bool
        var built: [Weak] = []
        var cellsBuilt = 0
        init(plain: Bool) { self.plain = plain }

        var alive: Int { built.filter { $0.row != nil }.count }

        func numberOfRows(in tableView: NSTableView) -> Int { 400 }
        func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
            let make: () -> NSTableRowView = { [self] in
                let made: NSTableRowView = row % 5 == 0 ? OtherRow() : Row()
                built.append(Weak(row: made))
                return made
            }
            return plain ? make() : tableView.reusableView(variant: row % 5 == 0 ? "other" : "", make)
        }
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let label = tableView.reusableView { [self] () -> NSTextField in
                let made = NSTextField(labelWithString: "")
                cellsBuilt += 1
                return made
            }
            label.stringValue = "row \(row)"
            return label
        }
    }

    /// The table in a window (an `NSTableView` takes another path through its row bookkeeping
    /// detached), and the window.
    private func makeTable(_ source: RowSource) -> (NSTableView, NSWindow) {
        let table = NSTableView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
        table.addTableColumn(NSTableColumn(identifier: .init("name")))
        table.headerView = nil
        table.dataSource = source
        table.delegate = source
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400), styleMask: [.titled], backing: .buffered, defer: false)
        let scroll = NSScrollView(frame: window.contentView!.bounds)
        scroll.documentView = table
        window.contentView?.addSubview(scroll)
        table.reloadData()
        window.layoutIfNeeded()
        return (table, window)
    }

    /// Jumps around the list the way a reveal does, draining autorelease pools as a run loop would.
    private func scrollAround(_ table: NSTableView, jumps: Int) {
        for i in 0..<jumps {
            autoreleasepool {
                table.scrollRowToVisible((i * 97) % table.numberOfRows)
                table.layoutSubtreeIfNeeded()
            }
        }
    }

    /// The leak this exists for: 300 jumps around a 400-row list leave about a screenful of row
    /// views alive, not every one ever shown. Built without the helper they all stay alive (the
    /// table's purgatory holds them), so this fails against a helper that does not dequeue.
    func testScrollingKeepsOnlyAScreenfulOfRowViews() {
        let source = RowSource(plain: false)
        let (table, window) = makeTable(source)
        let visible = table.rows(in: table.visibleRect).length
        scrollAround(table, jumps: 300)
        XCTAssertGreaterThan(visible, 5, "the rig shows rows")
        XCTAssertLessThanOrEqual(source.built.count, visible * 3, "row views built over 300 jumps: \(source.built.count)")
        XCTAssertLessThanOrEqual(source.alive, visible * 3, "row views alive after 300 jumps: \(source.alive), \(visible) on screen")
        withExtendedLifetime(window) {}
    }

    /// The rig reproduces the leak, so the test above can fail: row views built without the
    /// helper outlive their rows.
    func testPlainRowViewsOutliveTheirRows() {
        let source = RowSource(plain: true)
        let (table, window) = makeTable(source)
        let visible = table.rows(in: table.visibleRect).length
        scrollAround(table, jumps: 300)
        XCTAssertGreaterThan(source.alive, visible * 10, "AppKit no longer keeps undequeued row views; the helper's reason is gone")
        withExtendedLifetime(window) {}
    }

    /// Every row gets the kind of row view its factory made, each kind coming back as itself.
    func testEachRowKeepsTheKindItsFactoryMade() {
        let source = RowSource(plain: false)
        let (table, window) = makeTable(source)
        scrollAround(table, jumps: 100)
        let visible = table.rows(in: table.visibleRect)
        XCTAssertGreaterThan(visible.length, 5)
        for row in visible.location..<NSMaxRange(visible) {
            let view = table.rowView(atRow: row, makeIfNecessary: false)
            XCTAssertTrue(
                row % 5 == 0 ? view is RowSource.OtherRow : view is RowSource.Row,
                "row \(row) has a \(view.map { "\(type(of: $0))" } ?? "missing") row view")
        }
        withExtendedLifetime(window) {}
    }

    /// Cells come back too: a reload of the visible rows, the sidebar's git redecoration, builds
    /// none after the first pass.
    func testReloadingRowsReusesTheirCells() {
        let source = RowSource(plain: false)
        let (table, window) = makeTable(source)
        let visible = table.rows(in: table.visibleRect)
        let first = source.cellsBuilt
        for _ in 0..<50 {
            autoreleasepool {
                table.reloadData(forRowIndexes: IndexSet(integersIn: visible.location..<NSMaxRange(visible)), columnIndexes: [0])
                table.layoutSubtreeIfNeeded()
            }
        }
        XCTAssertGreaterThan(first, 5)
        XCTAssertLessThanOrEqual(
            source.cellsBuilt, first * 2, "cells built over 50 reloads of \(visible.length) rows: \(source.cellsBuilt)")
        withExtendedLifetime(window) {}
    }
}
