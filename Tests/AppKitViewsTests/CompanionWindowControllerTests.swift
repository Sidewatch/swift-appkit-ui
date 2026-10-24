//
//  CompanionWindowControllerTests.swift
//  AppKitViewsTests
//
//  `CompanionWindowController`: the view moves into the window and fills it, the red button asks
//  the host instead of closing, release gives the same view back and closes the window, and a
//  saved frame comes back.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import AppKitViews

/// Tests for `CompanionWindowController`.
@MainActor
final class CompanionWindowControllerTests: XCTestCase {
    private func companion(_ view: NSView, frame: String? = nil) -> CompanionWindowController {
        CompanionWindowController(
            hosting: view, title: "Terminal", frame: frame, defaultFrame: NSRect(x: 100, y: 100, width: 500, height: 300),
            minSize: NSSize(width: 200, height: 120))
    }

    /// On screen as AppKit sees it, but transparent and far off it, so a test run shows nothing.
    private func showQuietly(_ wc: CompanionWindowController) {
        wc.window?.alphaValue = 0
        wc.window?.setFrameOrigin(NSPoint(x: -20_000, y: -20_000))
        wc.window?.orderFront(nil)
    }

    func testTheViewMovesIntoTheWindowAndFillsIt() {
        let home = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        let panel = NSView()
        home.addSubview(panel)
        let wc = companion(panel)
        XCTAssertNil(home.subviews.first, "the view left where it was")
        XCTAssertTrue(panel.window === wc.window)
        wc.window?.contentView?.layoutSubtreeIfNeeded()
        XCTAssertEqual(panel.frame.size, wc.window?.contentView?.bounds.size)
        XCTAssertEqual(wc.window?.title, "Terminal")
    }

    func testTheRedButtonAsksTheHostAndDoesNotClose() {
        let wc = companion(NSView())
        var asked = 0
        wc.onCloseRequest = { asked += 1 }
        showQuietly(wc)
        wc.window?.performClose(nil)
        XCTAssertEqual(asked, 1)
        XCTAssertNotNil(wc.hostedView, "the view is still hosted")
        XCTAssertTrue(wc.window?.isVisible == true, "the window is still open")
        wc.release()
    }

    func testReleaseGivesTheSameViewBackAndClosesTheWindow() {
        let panel = NSView()
        let wc = companion(panel)
        showQuietly(wc)
        var asked = 0
        wc.onCloseRequest = { asked += 1 }
        let back = wc.release()
        XCTAssertTrue(back === panel)
        XCTAssertNil(panel.superview)
        XCTAssertFalse(wc.window?.isVisible ?? true)
        XCTAssertEqual(asked, 0, "release is the host's own close, not a request")
        XCTAssertNil(wc.release(), "nothing to release twice")
    }

    func testASavedFrameComesBack() {
        let first = companion(NSView())
        first.window?.setFrame(NSRect(x: 240, y: 180, width: 640, height: 360), display: false)
        let saved = first.frameDescriptor
        first.release()
        let second = companion(NSView(), frame: saved)
        XCTAssertEqual(second.window?.frame.size, NSSize(width: 640, height: 360))
        let fresh = companion(NSView())
        XCTAssertEqual(fresh.window?.contentLayoutRect.width ?? 0, 500, accuracy: 1, "no saved frame: the default")
        second.release()
        fresh.release()
    }
}
