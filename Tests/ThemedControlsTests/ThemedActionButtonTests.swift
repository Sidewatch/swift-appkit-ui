//
//  ThemedActionButtonTests.swift
//  ThemedControlsTests
//
//  `ThemedActionButton`: the primary capsule is the accent with `onAccent` text, the plain one has
//  no fill, the symbol sits on the side asked for, and a disabled button dims.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `ThemedActionButton`.
@MainActor
final class ThemedActionButtonTests: XCTestCase {
    /// The two colours' sRGB components, within rounding.
    private func assertSame(_ a: NSColor?, _ b: NSColor, file: StaticString = #filePath, line: UInt = #line) {
        guard let x = a?.usingColorSpace(.sRGB), let y = b.withAlphaComponent(1).usingColorSpace(.sRGB) else {
            return XCTFail("not convertible", file: file, line: line)
        }
        for (p, q) in [(x.redComponent, y.redComponent), (x.greenComponent, y.greenComponent), (x.blueComponent, y.blueComponent)] {
            XCTAssertEqual(p, q, accuracy: 0.01, file: file, line: line)
        }
    }

    func testThePrimaryCapsuleIsTheAccentWithOnAccentText() {
        let button = ThemedActionButton(title: "Continue", style: .primary, symbol: "chevron.right")
        assertSame(button.fillColor, ThemedControls.palette.accent)
        assertSame(button.titleColor, ThemedControls.palette.onAccent)
        XCTAssertEqual(button.layer?.cornerRadius, ThemedActionButton.height / 2, "a capsule")
        XCTAssertEqual(button.intrinsicContentSize.height, ThemedActionButton.height)
    }

    func testThePlainButtonHasNoFillAndTheMutedTone() {
        let button = ThemedActionButton(title: "Skip", style: .plain)
        XCTAssertNil(button.fillColor)
        XCTAssertNil(button.layer?.backgroundColor)
        assertSame(button.titleColor, ThemedControls.palette.mutedText)
    }

    func testTheSymbolSitsOnTheSideAskedFor() {
        let back = ThemedActionButton(title: "Back", style: .plain, symbol: "chevron.left", placement: .leading)
        XCTAssertNotNil(back.image)
        XCTAssertEqual(back.imagePosition, .imageLeading)
        let next = ThemedActionButton(title: "Continue", style: .primary, symbol: "chevron.right")
        XCTAssertEqual(next.imagePosition, .imageTrailing)
        next.symbol = nil
        XCTAssertNil(next.image)
        XCTAssertEqual(next.imagePosition, .noImage)
    }

    func testADisabledButtonDims() {
        let button = ThemedActionButton(title: "Continue", style: .primary)
        button.isEnabled = false
        XCTAssertEqual(button.titleColor.alphaComponent, 0.4, accuracy: 0.01)
        XCTAssertEqual(button.fillColor?.alphaComponent ?? 1, 0.4, accuracy: 0.01)
    }
}
