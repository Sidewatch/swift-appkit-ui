//
//  ThemedIconButtonTests.swift
//  ThemedControlsTests
//
//  The bar icon button: clear at rest, a fill under the pointer, the accent while on, the palette's
//  colours throughout.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `ThemedIconButton`: hover, on and theme states each paint from the palette.
@MainActor
final class ThemedIconButtonTests: XCTestCase {
    private struct Loud: ControlPalette {
        var isDark: Bool { true }
        var accent: NSColor { NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1) }
        var foreground: NSColor { NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1) }
        var selection: NSColor { .blue }
        var sidebarBackground: NSColor { .black }
        var sidebarText: NSColor { .gray }
        var statusText: NSColor { NSColor(srgbRed: 0, green: 1, blue: 0, alpha: 1) }
        var border: NSColor { .gray }
        var rowSeparator: NSColor { .gray }
        var mutedText: NSColor { .gray }
        var statusBackground: NSColor { .black }
        var smallFont: NSFont { .systemFont(ofSize: 9) }
        func elevatedSurface(dark: CGFloat, light: CGFloat) -> NSColor { .darkGray }
    }

    override func setUp() { ThemedControls.palette = Loud() }
    override func tearDown() { ThemedControls.palette = SystemPalette() }

    func testRestingIsClearHoverFillsAndLeavingClearsIt() {
        let b = ThemedIconButton(symbol: "magnifyingglass", label: "Find")
        XCTAssertNil(b.fillForTesting, "no bezel or fill at rest")
        XCTAssertEqual(b.contentTintColor, Loud().statusText)
        b.setHoveredForTesting(true)
        let hover = try? XCTUnwrap(b.fillForTesting?.usingColorSpace(.sRGB))
        XCTAssertEqual(hover?.alphaComponent ?? 0, 0.11, accuracy: 0.01, "a soft fill under the pointer")
        b.setHoveredForTesting(false)
        XCTAssertNil(b.fillForTesting)
    }

    func testOnPaintsTheAccentAndHidingDropsTheHover() {
        let b = ThemedIconButton(symbol: "eye", label: "Preview")
        b.isOn = true
        XCTAssertEqual(b.contentTintColor, Loud().accent)
        XCTAssertEqual(b.fillForTesting?.usingColorSpace(.sRGB)?.redComponent ?? 0, 1, accuracy: 0.01, "the faint fill is the accent")
        b.isOn = false
        b.setHoveredForTesting(true)
        b.isHidden = true
        XCTAssertNil(b.fillForTesting, "a hidden button forgets the pointer")
    }

    func testItIsASquare22PointsWithAnAccessibleName() {
        let b = ThemedIconButton(symbol: "ellipsis.circle", label: "View options")
        XCTAssertEqual(b.intrinsicContentSize, NSSize(width: 22, height: 22))
        XCTAssertEqual(b.accessibilityLabel(), "View options")
        XCTAssertEqual(b.toolTip, "View options")
        XCTAssertEqual(ThemedIconButton(symbol: "play", label: "Run", side: 18).intrinsicContentSize, NSSize(width: 18, height: 18))
    }
}
