//
//  PaletteTests.swift
//  ThemedControlsTests
//
//  Tests for the installed `ControlPalette`: a custom palette is what the controls read, and
//  `paletteDidChange` fires on install.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for the installed `ControlPalette`: a custom palette is what the controls read, and
/// `paletteDidChange` fires on install.
@MainActor
final class PaletteTests: XCTestCase {

    private struct Loud: ControlPalette {
        var isDark: Bool { true }
        var accent: NSColor { .red }
        var foreground: NSColor { .white }
        var selection: NSColor { .blue }
        var sidebarBackground: NSColor { .black }
        var sidebarText: NSColor { .gray }
        var statusText: NSColor { .gray }
        var border: NSColor { .gray }
        var rowSeparator: NSColor { .gray }
        var mutedText: NSColor { .gray }
        var statusBackground: NSColor { .black }
        var smallFont: NSFont { .systemFont(ofSize: 9) }
        func elevatedSurface(dark: CGFloat, light: CGFloat) -> NSColor { dark > light ? .darkGray : .lightGray }
    }

    func testTheSystemPaletteIsInstalledByDefaultAndCanBeReplaced() {
        XCTAssertTrue(ThemedControls.palette is SystemPalette)
        ThemedControls.palette = Loud()
        defer { ThemedControls.palette = SystemPalette() }
        XCTAssertEqual(ThemedControls.palette.accent, .red)
        XCTAssertEqual(ThemedControls.palette.elevatedSurface(dark: 0.1, light: 0.05), .darkGray)
    }

    func testAThemedSliderFillsItsTrackWithTheAccent() {
        let slider = ThemedSlider()
        ThemedControls.palette = Loud()
        defer { ThemedControls.palette = SystemPalette() }
        NotificationCenter.default.post(name: ThemedControls.paletteDidChange, object: nil)
        XCTAssertEqual(slider.trackFillColor, .red, "the filled track follows the palette, not the macOS accent")
    }

    func testTheSystemPaletteLiftsASurfaceTowardTheForeground() {
        let p = SystemPalette()
        XCTAssertNotEqual(p.elevatedSurface(dark: 0.2, light: 0.2), NSColor.windowBackgroundColor, "blended, not the raw background")
        XCTAssertEqual(p.smallFont.pointSize, NSFont.smallSystemFontSize)
    }
}
