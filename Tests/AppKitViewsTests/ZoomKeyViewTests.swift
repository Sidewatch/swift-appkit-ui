//
//  ZoomKeyViewTests.swift
//  AppKitViewsTests
//
//  The container answers the zoom keys before the menu, and never leaks a right-click.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import AppKitViews

@MainActor final class ZoomKeyViewTests: XCTestCase {
    private func key(_ chars: String, flags: NSEvent.ModifierFlags = .command) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: flags,
            timestamp: 0, windowNumber: 0, context: nil,
            characters: chars, charactersIgnoringModifiers: chars,
            isARepeat: false, keyCode: 0)!
    }

    func testCommandKeysReachTheHandler() {
        let view = ZoomKeyView()
        var seen: [ZoomKeyDirection] = []
        view.onZoomKey = {
            seen.append($0); return true
        }
        for (chars, expected) in [("=", ZoomKeyDirection.in), ("-", .out), ("0", .actual)] {
            XCTAssertTrue(view.performKeyEquivalent(with: key(chars)), "⌘\(chars) not consumed")
            XCTAssertEqual(seen.last, expected)
        }
    }

    /// The handler decides. A surface already at its limit returns false and the key goes on to
    /// the menu, which is how the editor's font size keeps working.
    func testTheHandlerCanDeclineAndTheKeyTravelsOn() {
        let view = ZoomKeyView()
        view.onZoomKey = { _ in false }
        XCTAssertFalse(view.performKeyEquivalent(with: key("=")))
    }

    func testWithNoHandlerNothingIsConsumed() {
        XCTAssertFalse(ZoomKeyView().performKeyEquivalent(with: key("=")))
    }

    /// ⌘ EXACTLY — ⌥⌘0 and ⇧⌘- belong to somebody else.
    func testOtherModifierCombinationsAreNotClaimed() {
        let view = ZoomKeyView()
        var fired = false
        view.onZoomKey = { _ in
            fired = true; return true
        }
        for flags: NSEvent.ModifierFlags in [[.command, .option], [.command, .shift], [.command, .control], [.option], []] {
            XCTAssertFalse(view.performKeyEquivalent(with: key("0", flags: flags)))
        }
        XCTAssertFalse(fired)
    }

    /// An EMPTY menu, never nil: nil lets the right-click climb to whatever sits beneath, which
    /// is how an editor's Cut / Go to Definition menu opened over an image.
    func testARightClickYieldsAnEmptyMenuRatherThanNil() {
        let view = ZoomKeyView()
        let click = NSEvent.mouseEvent(
            with: .rightMouseDown, location: NSPoint(x: 5, y: 5),
            modifierFlags: [], timestamp: 0, windowNumber: 0,
            context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
        let menu = view.menu(for: click)
        XCTAssertNotNil(menu, "nil would let the click reach the view beneath")
        XCTAssertEqual(menu?.items.count, 0)
    }
}
