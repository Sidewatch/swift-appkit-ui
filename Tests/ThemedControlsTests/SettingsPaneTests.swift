//
//  SettingsPaneTests.swift
//  ThemedControlsTests
//
//  The page column: a page that scrolls lays its cards out where one that fits does.
//
//  Created by David Sherlock on 10/20/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `SettingsPane.buildPane`: a scrolling page's cards and controls sit exactly where a
/// short page's do.
@MainActor
final class SettingsPaneTests: XCTestCase {
    private final class Pane: NSViewController, SettingsPane {
        let rows: Int
        let toggle = ThemedSwitch()
        init(rows: Int) {
            self.rows = rows
            super.init(nibName: nil, bundle: nil)
        }
        @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
        var paneTitle: String { "Test" }
        var paneSymbol: String { "gear" }
        func syncFromSettings() {}
        override func loadView() {
            view = NSView()
            var cards = [SettingsSection(header: "First", rows: [SettingsRowView("Switch", control: toggle)])]
            for i in 0..<rows { cards.append(SettingsSection(header: "Section \(i)", rows: [SettingsRowView("Row", control: NSView())])) }
            buildPane(cards)
            pinPaneSize()
        }
    }

    /// Lays `pane` out in a window as the Settings column would and returns the switch's frame in the pane.
    private func switchFrame(in pane: Pane) -> NSRect {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: SettingsMetrics.columnWidth, height: 400), styleMask: [.titled],
            backing: .buffered, defer: false)
        window.contentView = pane.view
        window.layoutIfNeeded()
        pane.view.layoutSubtreeIfNeeded()
        defer { window.orderOut(nil) }
        return pane.view.convert(pane.toggle.bounds, from: pane.toggle)
    }

    func testAScrollingPageKeepsItsControlsWhereAShortPageHasThem() {
        let short = switchFrame(in: Pane(rows: 0))
        let tall = Pane(rows: 30)
        let tallFrame = switchFrame(in: tall)
        XCTAssertGreaterThan(tall.contentHeight, 400, "the tall page overflows, so its scroller shows")
        XCTAssertEqual(tallFrame.minX, short.minX, accuracy: 0.5, "the switch does not move left when the page scrolls")
        XCTAssertEqual(
            short.maxX, SettingsMetrics.paneWidth - SettingsMetrics.margin - SettingsMetrics.cardInset, accuracy: 1,
            "and it sits against the page's card edge, inside the gutter")
    }
}
