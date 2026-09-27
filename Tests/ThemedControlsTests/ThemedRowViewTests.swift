//
//  ThemedRowViewTests.swift
//  ThemedControlsTests
//
//  How each themed row reports its interior style, which decides how AppKit draws its symbols.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

@MainActor
final class ThemedRowViewTests: XCTestCase {
    func testEachRowReportsItsOwnEmphasis() {
        func style(_ row: NSTableRowView, selected: Bool) -> NSView.BackgroundStyle {
            row.isSelected = selected
            return row.interiorBackgroundStyle
        }
        XCTAssertEqual(style(ThemedRowView(), selected: false), .emphasized, "the base row is always emphasized")
        XCTAssertEqual(style(ThemedSelectionRowView(), selected: false), .normal)
        XCTAssertEqual(style(ThemedSelectionRowView(), selected: true), .emphasized)
        XCTAssertEqual(style(ThemedPlainRowView(), selected: false), .normal)
        XCTAssertEqual(style(ThemedPlainRowView(), selected: true), .normal, "a plain row keeps its symbols' tints when selected")
    }
}
