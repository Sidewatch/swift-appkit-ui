//
//  RecyclingOutlineViewTests.swift
//  AppKitViewsTests
//
//  An outline reloaded again and again keeps a screenful of disclosure buttons.
//
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import AppKitViews

@MainActor final class RecyclingOutlineViewTests: XCTestCase {
    /// A plain outline that remembers, weakly, every disclosure button AppKit builds for it.
    private final class CountingOutlineView: NSOutlineView {
        struct Weak { weak var view: NSView? }
        var buttons: [Weak] = []
        override func makeView(withIdentifier identifier: NSUserInterfaceItemIdentifier, owner: Any?) -> NSView? {
            let made = super.makeView(withIdentifier: identifier, owner: owner)
            if identifier == NSOutlineView.disclosureButtonIdentifier, let made { buttons.append(Weak(view: made)) }
            return made
        }
        var alive: Int { buttons.filter { $0.view != nil }.count }
    }

    /// A fresh tree each generation, as a host's rebuilt model is: 8 expandable roots of 4.
    private final class Source: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
        final class Node {
            let children: [Node]
            init(_ children: [Node] = []) { self.children = children }
        }
        var roots: [Node] = []
        func regenerate() { roots = (0..<8).map { _ in Node((0..<4).map { _ in Node() }) } }

        func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            (item as? Node)?.children.count ?? roots.count
        }
        func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            (item as? Node)?.children[index] ?? roots[index]
        }
        func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
            !((item as? Node)?.children.isEmpty ?? true)
        }
        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            outlineView.reusableView { NSTextField(labelWithString: "node") }
        }
    }

    private func host(_ outline: NSOutlineView, _ source: Source) -> NSWindow {
        let column = NSTableColumn(identifier: .init("name"))
        outline.addTableColumn(column)
        outline.outlineTableColumn = column
        outline.headerView = nil
        outline.dataSource = source
        outline.delegate = source
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 600), styleMask: [.titled], backing: .buffered, defer: false)
        let scroll = NSScrollView(frame: window.contentView!.bounds)
        scroll.documentView = outline
        window.contentView?.addSubview(scroll)
        source.regenerate()
        outline.reloadData()
        window.layoutIfNeeded()
        return window
    }

    /// Lets the outline place its rows, as the run loop does between events: a reload only
    /// marks the content stale.
    private func settle(_ outline: NSOutlineView) {
        outline.window?.layoutIfNeeded()
        outline.window?.displayIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.002))
    }

    private func reload(_ outline: NSOutlineView, _ source: Source, times: Int, expand: Bool) {
        for _ in 0..<times {
            autoreleasepool {
                source.regenerate()
                outline.reloadData()
                if expand { outline.expandItem(nil, expandChildren: true) }
                settle(outline)
            }
        }
    }

    /// The leak this exists for: 200 reloads build a screenful of disclosure buttons, not one per
    /// expandable row per reload. Fails against an outline that does not hand its buttons back.
    func testReloadsBuildAScreenfulOfDisclosureButtons() {
        let outline = RecyclingOutlineView(frame: NSRect(x: 0, y: 0, width: 300, height: 600))
        let source = Source()
        let window = host(outline, source)
        reload(outline, source, times: 200, expand: true)
        XCTAssertEqual(outline.numberOfRows, 8 + 32, "the tree is open")
        XCTAssertGreaterThan(outline.outlineButtonsBuilt, 0, "the rig shows disclosure buttons")
        XCTAssertLessThanOrEqual(
            outline.outlineButtonsBuilt, 24, "disclosure buttons built over 200 reloads: \(outline.outlineButtonsBuilt)")
        withExtendedLifetime(window) {}
    }

    /// The rig reproduces the leak, so the test above can fail: a plain outline keeps every
    /// disclosure button it ever built.
    func testAPlainOutlineKeepsEveryDisclosureButton() {
        let outline = CountingOutlineView(frame: NSRect(x: 0, y: 0, width: 300, height: 600))
        let source = Source()
        let window = host(outline, source)
        reload(outline, source, times: 200, expand: false)
        XCTAssertGreaterThan(
            outline.alive, 8 * 100, "AppKit no longer keeps an outline's old disclosure buttons; the subclass's reason is gone")
        withExtendedLifetime(window) {}
    }

    /// A reused button still opens and closes its row.
    func testAReusedDisclosureButtonStillTogglesItsRow() throws {
        let outline = RecyclingOutlineView(frame: NSRect(x: 0, y: 0, width: 300, height: 600))
        let source = Source()
        let window = host(outline, source)
        reload(outline, source, times: 20, expand: false)
        let first = try XCTUnwrap(outline.item(atRow: 0))
        let button = try XCTUnwrap(
            outline.rowView(atRow: 0, makeIfNecessary: false)?.subviews.first { $0.identifier == NSOutlineView.disclosureButtonIdentifier }
                as? NSButton, "row 0 shows a disclosure button")
        button.performClick(nil)
        XCTAssertTrue(outline.isItemExpanded(first), "clicking the reused button opens the row")
        button.performClick(nil)
        XCTAssertFalse(outline.isItemExpanded(first), "and closes it again")
        withExtendedLifetime(window) {}
    }
}
