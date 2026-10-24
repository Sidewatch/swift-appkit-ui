//
//  SettingsSectionsViewTests.swift
//  ThemedControlsTests
//
//  `SettingsSectionsView` fills the width it is given, and a row with a symbol carries its tile
//  with the caption moved past it.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `SettingsSectionsView` and a symbol row.
@MainActor
final class SettingsSectionsViewTests: XCTestCase {
    private func lay(_ view: NSView, width: CGFloat) {
        let host = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 600))
        host.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            view.topAnchor.constraint(equalTo: host.topAnchor),
        ])
        host.layoutSubtreeIfNeeded()
    }

    func testTheCardsFillTheWidthGivenLessTheMargin() {
        for width: CGFloat in [500, 800] {
            let sections = SettingsSectionsView(
                sections: [SettingsSection(header: "A", rows: [SettingsRowView("One", control: ThemedSwitch())], footnote: "Note")],
                margin: 10)
            lay(sections, width: width)
            let card = sections.subviews.first { $0 is SettingsCard }
            XCTAssertEqual(card?.frame.width, width - 20, "at \(width)")
            XCTAssertGreaterThan(sections.frame.height, 0, "the view takes its content's height")
        }
    }

    func testASymbolRowCarriesItsTileAndMovesTheCaptionPastIt() {
        let plain = SettingsRowView("Line numbers", control: ThemedSwitch())
        let marked = SettingsRowView("Line numbers", control: ThemedSwitch(), symbol: "list.number")
        lay(SettingsCard(rows: [plain]), width: 500)
        lay(SettingsCard(rows: [marked]), width: 500)
        let tile = marked.subviews.compactMap { $0 as? SymbolTileView }.first
        XCTAssertNotNil(tile)
        XCTAssertTrue(tile?.hasSymbol == true)
        XCTAssertTrue(plain.subviews.allSatisfy { !($0 is SymbolTileView) })
        func captionX(_ row: SettingsRowView) -> CGFloat {
            row.subviews.first { ($0 as? SettingsLabel)?.stringValue == "Line numbers" }?.frame.minX ?? -1
        }
        XCTAssertGreaterThan(captionX(marked), captionX(plain) + SymbolTileView.side)
        XCTAssertFalse(tile?.isAccessibilityElement() ?? true, "the caption names the row; the tile is decoration")
    }
}
