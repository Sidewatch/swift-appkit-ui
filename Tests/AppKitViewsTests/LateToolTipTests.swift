//
//  LateToolTipTests.swift
//  AppKitViewsTests
//
//  A tooltip whose text is asked for only as it shows, following the view as it resizes.
//
//  Created by David Sherlock on 10/22/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import AppKitViews

@MainActor final class LateToolTipTests: XCTestCase {
    func testTheTextIsAskedForOnlyAsTheTooltipShows() {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 22))
        var asked = 0
        let tip = LateToolTip(on: view) {
            asked += 1
            return "Ignored by .gitignore:3 — build/"
        }
        view.setFrameSize(NSSize(width: 300, height: 22))
        XCTAssertEqual(asked, 0, "neither building it nor a resize asks for the words")
        XCTAssertEqual(tip.view(view, stringForToolTip: tip.tag ?? 0, point: .zero, userData: nil), "Ignored by .gitignore:3 — build/")
        XCTAssertEqual(asked, 1)
    }

    func testNoWordsShowNoTooltip() {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 22))
        let tip = LateToolTip(on: view) { nil }
        XCTAssertEqual(tip.currentText, "")
    }

    func testTheRectangleFollowsTheViewAsItResizes() throws {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 22))
        let tip = LateToolTip(on: view) { "x" }
        let first = try XCTUnwrap(tip.tag, "a rectangle is registered at once")
        view.setFrameSize(NSSize(width: 320, height: 22))
        let second = try XCTUnwrap(tip.tag)
        XCTAssertNotEqual(first, second, "a resize registers the rectangle again over the new bounds")
    }

    func testRemoveTakesItOffAndStopsFollowing() {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 22))
        let tip = LateToolTip(on: view) { "x" }
        tip.remove()
        XCTAssertNil(tip.tag)
        view.setFrameSize(NSSize(width: 320, height: 22))
        XCTAssertNil(tip.tag, "a removed tooltip does not come back on a resize")
    }

    func testItLeavesTheViewsOwnTooltipAlone() {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 22))
        view.toolTip = "The full path"
        let tip = LateToolTip(on: view) { "x" }
        tip.remove()
        XCTAssertEqual(view.toolTip, "The full path")
    }
}
