//
//  LeafIconCentreTests.swift
//  AppKitViewsTests
//
//  A leaf's icon stands centred in the chevron column, in the outline column only, and only when asked.
//
//  Created by David Sherlock on 11/7/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import AppKitViews

@MainActor final class LeafIconCentreTests: XCTestCase {
    private var window: NSWindow!

    override func tearDown() {
        window?.orderOut(nil)
        window = nil
        super.tearDown()
    }

    /// `dir` (holding `a` and `sub`, which holds `b`) and `top`, all open, with a second column.
    private func outline() -> (RecyclingOutlineView, TreeSource) {
        let outline = RecyclingOutlineView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))
        let name = NSTableColumn(identifier: .init("name")), size = NSTableColumn(identifier: .init("size"))
        name.width = 260
        outline.addTableColumn(name)
        outline.addTableColumn(size)
        outline.outlineTableColumn = name
        let source = TreeSource(roots: [TreeNode("dir", [TreeNode("a"), TreeNode("sub", [TreeNode("b")])]), TreeNode("top")])
        outline.dataSource = source
        outline.reloadData()
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 500), styleMask: [.titled], backing: .buffered, defer: false)
        let scroll = NSScrollView(frame: window.contentView!.bounds)
        scroll.documentView = outline
        window.contentView?.addSubview(scroll)
        outline.expandItem(nil, expandChildren: true)
        window.layoutIfNeeded()
        return (outline, source)
    }

    private func row(_ name: String, in outline: NSOutlineView) -> Int {
        (0..<outline.numberOfRows).first { (outline.item(atRow: $0) as? TreeNode)?.name == name } ?? -1
    }

    func testTheChevronSitsWhereTheConstantSays() {
        let (outline, _) = outline()
        for folder in ["dir", "sub"] {
            let r = row(folder, in: outline)
            let chevron = outline.frameOfOutlineCell(atRow: r).midX, cell = outline.frameOfCell(atColumn: 0, row: r).minX
            XCTAssertEqual(cell - chevron, RecyclingOutlineView.chevronCentreBeforeCell, accuracy: 0.5, folder)
        }
    }

    func testALeafIconIsCentredOnItsLevelsChevron() {
        let (outline, _) = outline()
        outline.leafIconCentre = 10
        outline.reloadData()
        outline.expandItem(nil, expandChildren: true)
        let level0 = outline.frameOfOutlineCell(atRow: row("dir", in: outline)).midX
        let level1 = outline.frameOfOutlineCell(atRow: row("sub", in: outline)).midX
        XCTAssertEqual(outline.frameOfCell(atColumn: 0, row: row("top", in: outline)).minX + 10, level0, accuracy: 0.5)
        XCTAssertEqual(outline.frameOfCell(atColumn: 0, row: row("a", in: outline)).minX + 10, level1, accuracy: 0.5)
        let dir = row("dir", in: outline)
        XCTAssertEqual(
            outline.frameOfCell(atColumn: 0, row: dir).minX - outline.frameOfOutlineCell(atRow: dir).midX,
            RecyclingOutlineView.chevronCentreBeforeCell, accuracy: 0.5, "a folder's own cell does not move")
    }

    func testOnlyTheOutlineColumnMovesAndOnlyWhenAsked() {
        let (outline, _) = outline()
        let r = row("top", in: outline)
        let plain = (outline.frameOfCell(atColumn: 0, row: r), outline.frameOfCell(atColumn: 1, row: r))
        let folderCell = outline.frameOfCell(atColumn: 0, row: row("dir", in: outline))
        XCTAssertEqual(plain.0.minX, folderCell.minX, accuracy: 0.5, "nil: AppKit's place")
        outline.leafIconCentre = 10
        XCTAssertEqual(outline.frameOfCell(atColumn: 1, row: r), plain.1, "the size column stays")
        XCTAssertEqual(outline.frameOfCell(atColumn: 0, row: r).maxX, plain.0.maxX, accuracy: 0.5, "the cell keeps its trailing edge")
    }
}
