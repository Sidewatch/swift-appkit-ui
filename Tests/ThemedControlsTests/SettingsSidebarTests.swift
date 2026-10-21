//
//  SettingsSidebarTests.swift
//  ThemedControlsTests
//
//  The settings sidebar reports only the person's picks, and a re-theme keeps the page.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import ThemedControls

/// `SettingsSidebarView` and `ControlPalette.onAccent`.
@MainActor
final class SettingsSidebarTests: XCTestCase {
    private func sidebar() -> SettingsSidebarView {
        let view = SettingsSidebarView(pages: [("General", "gearshape"), ("Editor", "doc.text"), ("Terminal", "terminal")])
        view.frame = NSRect(x: 0, y: 0, width: 200, height: 300)
        view.layoutSubtreeIfNeeded()
        return view
    }

    func testAProgrammaticMoveIsSilentAndAPickIsReported() {
        let view = sidebar()
        var picked: [Int] = []
        view.onSelect = { picked.append($0) }
        view.select(1, notify: false)
        XCTAssertEqual(view.selectedIndex, 1)
        XCTAssertEqual(picked, [], "a move the host made is not echoed")
        view.select(2, notify: true)
        XCTAssertEqual(picked, [2])
        XCTAssertEqual(view.rowLabelsForTesting, ["General", "Editor", "Terminal"])
    }

    /// A re-theme reloads the table, which in a table that allows no empty selection jumps to row 0
    /// and reports it as a pick: picking a theme on one page used to jump to the first.
    func testAReThemeKeepsThePageAndReportsNothing() {
        let view = sidebar()
        view.select(2, notify: false)
        var picked: [Int] = []
        view.onSelect = { picked.append($0) }
        view.applyTheme()
        XCTAssertEqual(view.selectedIndex, 2)
        XCTAssertEqual(picked, [])
    }

    func testTextOnTheAccentReadsOnIt() {
        XCTAssertEqual(NSColor.white.textOnTop, NSColor.black.withAlphaComponent(0.85), "dark text on a light fill")
        XCTAssertEqual(NSColor(srgbRed: 0.1, green: 0.2, blue: 0.6, alpha: 1).textOnTop, .white)
    }
}
