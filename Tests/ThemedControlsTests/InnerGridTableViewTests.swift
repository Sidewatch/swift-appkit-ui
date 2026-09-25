//
//  InnerGridTableViewTests.swift
//  ThemedControlsTests
//
//  A table's vertical grid lines divide columns; they do not frame the table.
//
//  Created by David Sherlock on 9/25/26.
//

import XCTest
import AppKit
@testable import ThemedControls

@MainActor
final class InnerGridTableViewTests: XCTestCase {
    private func table(columns: Int) -> InnerGridTableView {
        let t = InnerGridTableView(frame: NSRect(x: 0, y: 0, width: 400, height: 100))
        for i in 0..<columns {
            let c = NSTableColumn(identifier: .init("c\(i)"))
            c.width = 100
            t.addTableColumn(c)
        }
        return t
    }

    func testADividerSitsBetweenEveryPairOfColumnsAndNowhereElse() {
        let t = table(columns: 4)
        let xs = t.dividerXsForTesting
        XCTAssertEqual(xs.count, 3, "four columns have three boundaries — not five")
        XCTAssertFalse(xs.contains { $0 <= t.rect(ofColumn: 0).minX }, "nothing on the leading edge")
        XCTAssertFalse(xs.contains { $0 >= t.rect(ofColumn: 3).maxX - 1.5 }, "nothing on the trailing edge")
        for (i, x) in xs.enumerated() {
            XCTAssertEqual(x, t.rect(ofColumn: i).maxX - 1, accuracy: 0.01, "between column \(i) and \(i + 1)")
        }
    }

    func testOneColumnHasNoDividerAtAll() {
        XCTAssertTrue(table(columns: 1).dividerXsForTesting.isEmpty, "there is nothing to divide")
        XCTAssertTrue(table(columns: 0).dividerXsForTesting.isEmpty)
    }

    /// The lines are DRAWN, not merely computed: drawing the grid of a two-column table puts
    /// ink at the boundary and leaves the table's own edges clear. `drawGrid(inClipRect:)` is
    /// called directly — when AppKit calls it is AppKit's contract; what it paints is ours.
    func testTheDividerIsDrawnAndTheEdgesAreNot() throws {
        let t = table(columns: 2)
        t.gridStyleMask = []
        t.dividerColor = .white
        let image = NSImage(size: t.bounds.size)
        image.lockFocus()
        NSColor.black.setFill()
        t.bounds.fill()
        t.drawGrid(inClipRect: t.bounds)
        image.unlockFocus()
        let rep = try XCTUnwrap(NSBitmapImageRep(data: image.tiffRepresentation ?? Data()))
        let scale = CGFloat(rep.pixelsWide) / t.bounds.width
        func isLit(_ x: CGFloat) -> Bool {
            (0..<rep.pixelsHigh).contains { y in
                (rep.colorAt(x: min(rep.pixelsWide - 1, Int(x * scale)), y: y)?.brightnessComponent ?? 0) > 0.5
            }
        }
        XCTAssertTrue(isLit(t.rect(ofColumn: 0).maxX - 1), "a divider between the two columns")
        XCTAssertFalse(isLit(0), "nothing down the table's leading edge")
        XCTAssertFalse(isLit(t.rect(ofColumn: 1).maxX - 1), "nothing down its trailing edge")
    }
}
