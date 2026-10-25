//
//  ThemedPopUpButtonTests.swift
//  ThemedControlsTests
//
//  `ThemedPopUpButton`: the stock pop-up's size — 24 pt tall at its default 13 pt, compact at a
//  caller's 11 pt — and wide enough for its widest item without truncation.
//
//  Created by David Sherlock on 10/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `ThemedPopUpButton`.
@MainActor
final class ThemedPopUpButtonTests: XCTestCase {
    func testTheStockHeightAtTheDefaultTextAndCompactAtASmallerOne() {
        let popup = ThemedPopUpButton()
        popup.addItems(withTitles: ["Bottom"])
        XCTAssertEqual(popup.font?.pointSize, NSFont.systemFontSize, "the stock pop-up's 13 pt")
        XCTAssertEqual(popup.intrinsicContentSize.height, 24, "the stock pop-up's height")
        popup.font = .systemFont(ofSize: 11)
        XCTAssertEqual(popup.intrinsicContentSize.height, 20, "a compact caller stays compact")
    }

    func testWideEnoughForTheWidestItemAtEitherSize() {
        for size in [CGFloat(13), 11] {
            let popup = ThemedPopUpButton()
            popup.font = .systemFont(ofSize: size)
            popup.addItems(withTitles: ["Left", "All prompts and snippets", "Right"])
            let text = ("All prompts and snippets" as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: size)]).width
            XCTAssertGreaterThanOrEqual(
                popup.intrinsicContentSize.width, text + 10 + (size * 0.85).rounded() + 16,
                "the widest item fits beside the arrows at \(size) pt")
        }
    }
}
