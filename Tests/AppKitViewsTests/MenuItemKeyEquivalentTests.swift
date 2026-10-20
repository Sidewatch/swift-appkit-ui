//
//  MenuItemKeyEquivalentTests.swift
//  AppKitViewsTests
//
//  `keyEquivalentDisplay` and `keyCombo`: the implied Shift of a capital key, arrows and function
//  keys by name, and two spellings of one shortcut as one combo.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import AppKitViews

/// `NSMenuItem.keyEquivalentDisplay` and `keyCombo`.
@MainActor
final class MenuItemKeyEquivalentTests: XCTestCase {
    private func item(_ key: String, _ mods: NSEvent.ModifierFlags) -> NSMenuItem {
        let item = NSMenuItem(title: "x", action: nil, keyEquivalent: key)
        item.keyEquivalentModifierMask = mods
        return item
    }

    func testACapitalKeyShowsTheShiftItImplies() {
        XCTAssertEqual(item("f", .command).keyEquivalentDisplay, "⌘F")
        XCTAssertEqual(item("F", .command).keyEquivalentDisplay, "⇧⌘F", "Find in Files is not Find")
        XCTAssertEqual(item("o", [.command, .option]).keyEquivalentDisplay, "⌥⌘O")
    }

    func testModifiersComeInTheMenuBarsOrder() {
        XCTAssertEqual(item("d", [.command, .shift, .control, .option]).keyEquivalentDisplay, "⌃⌥⇧⌘D")
    }

    func testArrowAndFunctionKeysAreNamed() {
        let down = String(UnicodeScalar(NSDownArrowFunctionKey)!)
        XCTAssertEqual(item(down, [.command, .option]).keyEquivalentDisplay, "⌥⌘↓")
        XCTAssertEqual(item(String(UnicodeScalar(NSF5FunctionKey)!), []).keyEquivalentDisplay, "F5")
        XCTAssertEqual(item("\u{8}", .command).keyEquivalentDisplay, "⌘⌫")
    }

    func testNoShortcutIsEmpty() {
        XCTAssertEqual(item("", .command).keyEquivalentDisplay, "")
        XCTAssertNil(item("", .command).keyCombo)
    }

    func testTwoSpellingsOfOneShortcutAreOneCombo() {
        XCTAssertEqual(item("O", .command).keyCombo, item("o", [.command, .shift]).keyCombo)
        XCTAssertNotEqual(item("o", .command).keyCombo, item("O", .command).keyCombo)
    }
}
