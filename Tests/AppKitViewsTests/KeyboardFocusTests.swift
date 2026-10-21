//
//  KeyboardFocusTests.swift
//  AppKitViewsTests
//
//  `NSView.containsKeyboardFocus`: the view, its descendants, nothing else.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import AppKitViews

/// `NSView.containsKeyboardFocus`.
@MainActor
final class KeyboardFocusTests: XCTestCase {
    func testTheFocusedViewItsAncestorsAndNothingElseContainTheKeyboard() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200), styleMask: [.titled], backing: .buffered, defer: true)
        let pane = NSView(), sibling = NSView()
        let text = NSTextView(frame: NSRect(x: 0, y: 0, width: 50, height: 20))
        pane.addSubview(text)
        window.contentView?.addSubview(pane)
        window.contentView?.addSubview(sibling)
        XCTAssertTrue(window.makeFirstResponder(text))
        XCTAssertTrue(text.containsKeyboardFocus, "the focused view itself")
        XCTAssertTrue(pane.containsKeyboardFocus, "an ancestor")
        XCTAssertFalse(sibling.containsKeyboardFocus)
        XCTAssertFalse(NSView().containsKeyboardFocus, "no window")
        window.makeFirstResponder(nil)
        XCTAssertFalse(pane.containsKeyboardFocus, "the window holds it")
    }
}
