//
//  SettingsRestoreDefaultsButtonTests.swift
//  ThemedControlsTests
//
//  A page that restores its defaults ends with the button at the cards' trailing edge; a click
//  asks in a sheet; Restore Defaults restores and re-reads the page, Cancel leaves it; a page
//  that does not restore has no button.
//
//  Created by David Sherlock on 10/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `SettingsRestoreDefaultsButton` and `buildPane`'s placing of it.
@MainActor
final class SettingsRestoreDefaultsButtonTests: XCTestCase {
    private class Pane: NSViewController, SettingsPane {
        var syncs = 0
        var paneTitle: String { "Test" }
        var paneSymbol: String { "gear" }
        func syncFromSettings() { syncs += 1 }
        override func loadView() {
            view = NSView()
            buildPane([SettingsSection(header: "First", rows: [SettingsRowView("Switch", control: ThemedSwitch())])])
        }
    }
    private final class RestoringPane: Pane, SettingsDefaultsRestoring {
        var restores = 0
        func restoreDefaults() { restores += 1 }
    }

    private func host(_ pane: Pane) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: SettingsMetrics.columnWidth, height: 400), styleMask: [.titled],
            backing: .buffered, defer: false)
        window.contentView = pane.view
        window.layoutIfNeeded()
        pane.view.layoutSubtreeIfNeeded()
        return window
    }

    private func button(in view: NSView) -> SettingsRestoreDefaultsButton? {
        if let b = view as? SettingsRestoreDefaultsButton { return b }
        return view.subviews.lazy.compactMap { self.button(in: $0) }.first
    }

    private func spin() { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2)) }

    func testTheButtonEndsThePageAtTheCardsTrailingEdge() throws {
        let pane = RestoringPane()
        let window = host(pane)
        defer { window.orderOut(nil) }
        let restore = try XCTUnwrap(button(in: pane.view), "a restoring page has the button")
        let frame = pane.view.convert(restore.bounds, from: restore)
        XCTAssertEqual(frame.maxX, SettingsMetrics.paneWidth - SettingsMetrics.margin, accuracy: 1, "at the cards' trailing edge")
        XCTAssertNil(button(in: host(Pane()).contentView!), "a page that does not restore has none")
    }

    func testRestoreAsksThenRestoresAndRereadsOrCancelsAndLeavesIt() throws {
        let pane = RestoringPane()
        let window = host(pane)
        defer { window.orderOut(nil) }
        let restore = try XCTUnwrap(button(in: pane.view))
        restore.performClick(nil)
        spin()
        var sheet = try XCTUnwrap(window.attachedSheet, "the click asks first")
        XCTAssertEqual(pane.restores, 0, "nothing restores before the answer")
        window.endSheet(sheet, returnCode: .alertSecondButtonReturn)
        spin()
        XCTAssertEqual(pane.restores, 0, "Cancel leaves the page")
        restore.performClick(nil)
        spin()
        sheet = try XCTUnwrap(window.attachedSheet)
        window.endSheet(sheet, returnCode: .alertFirstButtonReturn)
        spin()
        XCTAssertEqual(pane.restores, 1, "Restore Defaults restores")
        XCTAssertEqual(pane.syncs, 1, "and the page re-reads its settings")
        let alert = SettingsRestoreDefaultsButton.makeAlert()
        XCTAssertEqual(alert.buttons.map(\.title), ["Restore Defaults", "Cancel"])
        XCTAssertEqual(alert.buttons.last?.keyEquivalent, "\u{1b}", "Escape answers Cancel")
    }
}
