//
//  MenuSeparatorTests.swift
//  AppKitViewsTests
//
//  `hideRedundantSeparators`: no separator at the top, the bottom or twice in a row once items
//  hide, and every one back when they show again.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import AppKitViews

/// `NSMenu.hideRedundantSeparators()`.
@MainActor
final class MenuSeparatorTests: XCTestCase {
    /// A menu from a pattern: a letter is an item, `-` a separator.
    private func menu(_ pattern: String) -> NSMenu {
        let menu = NSMenu()
        for character in pattern {
            menu.addItem(character == "-" ? .separator() : NSMenuItem(title: String(character), action: nil, keyEquivalent: ""))
        }
        return menu
    }

    /// What draws: shown items' titles, `-` for a shown separator.
    private func drawn(_ menu: NSMenu) -> String {
        menu.items.filter { !$0.isHidden }.map { $0.isSeparatorItem ? "-" : $0.title }.joined()
    }

    private func hide(_ titles: Set<String>, in menu: NSMenu) {
        for item in menu.items where titles.contains(item.title) { item.isHidden = true }
    }

    func testNothingHiddenKeepsEverySeparatorBetweenGroups() {
        let m = menu("ab-c-de")
        m.hideRedundantSeparators()
        XCTAssertEqual(drawn(m), "ab-c-de")
    }

    func testAHiddenGroupLeavesOneSeparatorNotTwo() {
        let m = menu("ab-c-de")
        hide(["c"], in: m)
        m.hideRedundantSeparators()
        XCTAssertEqual(drawn(m), "ab-de")
    }

    func testNoSeparatorAtTheTopOrTheBottom() {
        let m = menu("-ab-c-")
        m.hideRedundantSeparators()
        XCTAssertEqual(drawn(m), "ab-c")
        let n = menu("ab-c-de")
        hide(["a", "b"], in: n)
        n.hideRedundantSeparators()
        XCTAssertEqual(drawn(n), "c-de", "the first group hidden, its separator goes with it")
        hide(["d", "e"], in: n)
        n.hideRedundantSeparators()
        XCTAssertEqual(drawn(n), "c", "the last group hidden too")
    }

    func testEverythingHiddenDrawsNothing() {
        let m = menu("a-b")
        hide(["a", "b"], in: m)
        m.hideRedundantSeparators()
        XCTAssertEqual(drawn(m), "")
    }

    func testShowingTheItemsAgainBringsTheirSeparatorsBack() {
        let m = menu("ab-c-de")
        hide(["c", "d", "e"], in: m)
        m.hideRedundantSeparators()
        XCTAssertEqual(drawn(m), "ab")
        for item in m.items where !item.isSeparatorItem { item.isHidden = false }
        m.hideRedundantSeparators()
        XCTAssertEqual(drawn(m), "ab-c-de")
    }
}
