//
//  HiddenPaneSplitViewTests.swift
//  AppKitViewsTests
//
//  A hidden pane leaves no divider line, whichever pane it is and whichever way the split runs.
//
//  Created by David Sherlock on 11/7/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import AppKitViews

@MainActor final class HiddenPaneSplitViewTests: XCTestCase {
    private var window: NSWindow!

    override func tearDown() {
        window?.orderOut(nil)
        window = nil
        super.tearDown()
    }

    /// Two panes in a layer-backed window, the divider between them at 300.
    private func split(vertical: Bool, using type: NSSplitView.Type = HiddenPaneSplitView.self) -> NSSplitView {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600), styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView?.wantsLayer = true
        let split = type.init(frame: window.contentView!.bounds)
        split.isVertical = vertical
        split.dividerStyle = .thin
        split.addSubview(NSView())
        split.addSubview(NSView())
        window.contentView?.addSubview(split)
        split.adjustSubviews()
        split.setPosition(300, ofDividerAt: 0)
        settle(split)
        return split
    }

    /// The divider layers AppKit keeps in the split view that a person could see: inside it, with area.
    private func visibleDividers(_ split: NSSplitView) -> [CGRect] {
        (split.layer?.sublayers ?? []).filter { $0.delegate === split && $0.backgroundColor != nil && !$0.isHidden }.map(\.frame)
            .filter { $0.width > 0 && $0.height > 0 && $0.intersects(split.bounds) }
    }

    /// Lays out and draws twice, as the run loop's next turns would: AppKit makes the divider's layer
    /// on one pass and places it on the next.
    private func settle(_ split: NSSplitView) {
        for _ in 0..<2 {
            split.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
        }
    }

    private func hide(_ index: Int, in split: NSSplitView) {
        split.subviews[index].isHidden = true
        split.adjustSubviews()
        settle(split)
    }

    func testTheDividerShowsWhileBothPanesDo() {
        let split = split(vertical: true)
        XCTAssertGreaterThan(split.dividerThickness, 0)
        XCTAssertEqual(visibleDividers(split).count, 1, "AppKit draws the thin divider as a layer; if it stops, these tests prove nothing")
    }

    func testHidingEitherPaneLeavesNoLineEitherWay() {
        for vertical in [true, false] {
            for index in [0, 1] {
                let split = split(vertical: vertical)
                hide(index, in: split)
                XCTAssertEqual(split.dividerThickness, 0)
                XCTAssertEqual(visibleDividers(split), [], "vertical=\(vertical), pane \(index) hidden")
                XCTAssertEqual(split.subviews[1 - index].frame, split.bounds, "the shown pane takes the whole split")
            }
        }
    }

    /// Plain NSSplitView, for contrast: the first pane hidden leaves the divider inside the second.
    func testAPlainSplitViewLeavesALine() {
        let split = split(vertical: true, using: NSSplitView.self)
        hide(0, in: split)
        XCTAssertFalse(visibleDividers(split).isEmpty)
    }

    func testAnAdjustmentAsksForLayout() {
        let split = split(vertical: false)
        split.subviews[1].isHidden = true
        split.adjustSubviews()
        XCTAssertTrue(split.needsLayout, "the divider layer moves only in layout")
    }

    func testShowingThePaneAgainBringsTheDividerBack() {
        let split = split(vertical: true)
        hide(1, in: split)
        split.subviews[1].isHidden = false
        split.adjustSubviews()
        split.setPosition(300, ofDividerAt: 0)
        settle(split)
        XCTAssertGreaterThan(split.dividerThickness, 0)
        XCTAssertEqual(visibleDividers(split).count, 1)
    }
}
