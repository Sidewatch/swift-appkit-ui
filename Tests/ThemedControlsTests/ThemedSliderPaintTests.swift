//
//  ThemedSliderPaintTests.swift
//  ThemedControlsTests
//
//  What the slider PAINTS in its filled track, not what property it set.
//
//  Created by David Sherlock on 9/18/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Renders a `ThemedSlider` under a red-accent palette and reads the pixels of the filled part
/// of the track: they must be red-dominant. The property alone proved nothing on screen.
@MainActor
final class ThemedSliderPaintTests: XCTestCase {
    private struct RedAccent: ControlPalette {
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
        func elevatedSurface(dark: CGFloat, light: CGFloat) -> NSColor { .darkGray }
    }

    func testTheFilledTrackPaintsTheAccent() throws {
        ThemedControls.palette = RedAccent()
        defer { ThemedControls.palette = SystemPalette() }
        NotificationCenter.default.post(name: ThemedControls.paletteDidChange, object: nil)
        let slider = ThemedSlider(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        slider.minValue = 0; slider.maxValue = 10; slider.doubleValue = 8  // filled to 80%
        slider.appearance = NSAppearance(named: .darkAqua)
        let rep = try XCTUnwrap(slider.bitmapImageRepForCachingDisplay(in: slider.bounds))
        slider.cacheDisplay(in: slider.bounds, to: rep)
        let scale = CGFloat(rep.pixelsWide) / slider.bounds.width
        // Sample a band across the filled part (10%…50% of the width), the track's centre row.
        var reds = 0, samples = 0
        for px in stride(from: Int(20 * scale), to: Int(100 * scale), by: 2) {
            guard let c = rep.colorAt(x: px, y: rep.pixelsHigh / 2)?.usingColorSpace(.sRGB) else { continue }
            samples += 1
            if c.redComponent > 0.6, c.greenComponent < 0.35, c.blueComponent < 0.35 { reds += 1 }
        }
        XCTAssertGreaterThan(samples, 10)
        XCTAssertGreaterThan(
            Double(reds) / Double(max(samples, 1)), 0.6,
            "\(reds)/\(samples) red pixels — the fill is not the palette accent")
    }
}
