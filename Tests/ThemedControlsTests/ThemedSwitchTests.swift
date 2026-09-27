//
//  ThemedSwitchTests.swift
//  ThemedControlsTests
//
//  The switch's contract: the stock footprint, toggle fires once, a set state is silent, the
//  painted track is the palette accent when on.
//
//  Created by David Sherlock on 9/19/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `ThemedSwitch`: footprint, action firing, silent state set, disabled, and the
/// pixels of the track under a red-accent palette.
@MainActor
final class ThemedSwitchTests: XCTestCase {
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

    private final class Counter: NSObject {
        var fired = 0
        @objc func toggled(_ sender: Any?) { fired += 1 }
    }

    /// The paint matches the stock switch's visible track (measured 24 Sep 2026: regular 32 × 21,
    /// small 26 × 17, mini 21 × 14 inside a 54 × 24 frame), at the trailing end of the footprint,
    /// centred vertically — the footprint itself is unchanged, so layouts do not move.
    func testTrackIsTheStockSwitchsVisibleSizeInsideTheFootprint() {
        for (size, want) in [(NSControl.ControlSize.regular, NSSize(width: 32, height: 21)), (.small, NSSize(width: 26, height: 17)), (.mini, NSSize(width: 21, height: 14))] {
            let sw = ThemedSwitch()
            sw.controlSize = size
            sw.frame = NSRect(origin: .zero, size: sw.intrinsicContentSize)
            let track = sw.trackRect
            XCTAssertEqual(track.size, want, "\(size)")
            XCTAssertEqual(track.maxX, sw.bounds.maxX - 2, accuracy: 0.01, "\(size): trailing edge")
            XCTAssertEqual(track.midY, sw.bounds.midY, accuracy: 0.5, "\(size): centred")
            XCTAssertTrue(sw.bounds.contains(track), "\(size): inside the footprint")
        }
        XCTAssertEqual(ThemedSwitch().intrinsicContentSize, NSSwitch().intrinsicContentSize, "the footprint is still the stock one")
    }

    func testTheFootprintIsTheStockSwitchs() {
        XCTAssertEqual(ThemedSwitch().intrinsicContentSize, NSSwitch().intrinsicContentSize)
    }

    /// A header strip wants the small switch (23 Sep 2026): the footprint follows the control
    /// size, as the stock switch's does, and the drawing is bounds-relative so it scales with it.
    func testTheFootprintFollowsTheControlSize() {
        let sw = ThemedSwitch(frame: .zero)
        let regular = sw.intrinsicContentSize
        sw.controlSize = .small
        let small = sw.intrinsicContentSize
        sw.controlSize = .mini
        let mini = sw.intrinsicContentSize
        XCTAssertLessThan(small.width, regular.width)
        XCTAssertLessThan(small.height, regular.height)
        XCTAssertLessThan(mini.height, small.height)
        XCTAssertEqual(small.height, (regular.height * 0.78).rounded(), "small is the HIG's ratio of regular; the stock switch reports one size for every controlSize")
        XCTAssertEqual(regular, NSSwitch().intrinsicContentSize)
        sw.controlSize = .regular
        XCTAssertEqual(sw.intrinsicContentSize, regular)
    }

    func testToggleFlipsAndFiresOnceAndASetStateIsSilent() {
        let sw = ThemedSwitch()
        let counter = Counter()
        sw.target = counter; sw.action = #selector(Counter.toggled(_:))
        sw.toggle()
        XCTAssertEqual(sw.state, .on)
        XCTAssertEqual(counter.fired, 1)
        sw.state = .off
        XCTAssertEqual(counter.fired, 1, "setting the state programmatically does not fire the action")
        sw.isEnabled = false
        sw.toggle()
        XCTAssertEqual(sw.state, .off, "a disabled switch ignores the click")
        XCTAssertEqual(counter.fired, 1)
    }

    /// On screen the knob slides; under Reduce Motion it snaps.
    func testReduceMotionSnapsInsteadOfSliding() {
        let host = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100), styleMask: [.titled], backing: .buffered, defer: false)
        let sw = ThemedSwitch()
        host.contentView?.addSubview(sw)
        let before = ThemedControls.reduceMotion
        defer { ThemedControls.reduceMotion = before }
        ThemedControls.reduceMotion = true
        sw.state = .on
        XCTAssertFalse(sw.isSliding, "Reduce Motion: no slide")
        ThemedControls.reduceMotion = false
        sw.state = .off
        XCTAssertTrue(sw.isSliding, "otherwise the knob slides over 0.18 s")
        host.orderOut(nil)
    }

    /// Renders the switch on and off and reads the track where the knob is not.
    func testTheTrackPaintsTheAccentWhenOnAndNotWhenOff() throws {
        ThemedControls.palette = RedAccent()
        defer { ThemedControls.palette = SystemPalette() }
        let sw = ThemedSwitch(frame: NSRect(origin: .zero, size: NSSwitch().intrinsicContentSize))
        func redShare(_ side: CGFloat) throws -> Double {
            let rep = try XCTUnwrap(sw.bitmapImageRepForCachingDisplay(in: sw.bounds))
            sw.cacheDisplay(in: sw.bounds, to: rep)
            let scale = CGFloat(rep.pixelsWide) / sw.bounds.width
            var reds = 0, samples = 0
            // Sampled along the TRACK (the paint sits at the trailing end of the footprint since
            // 24 Sep 2026), `side` a fraction of its width, on its centre line.
            let track = sw.trackRect
            let y = Int((sw.bounds.maxY - track.midY) * scale)   // rep rows run top-down
            for px in stride(from: Int((track.minX + track.width * (side - 0.08)) * scale), to: Int((track.minX + track.width * (side + 0.08)) * scale), by: 1) {
                guard let c = rep.colorAt(x: px, y: y)?.usingColorSpace(.sRGB) else { continue }
                samples += 1
                if c.redComponent > 0.6, c.greenComponent < 0.35, c.blueComponent < 0.35 { reds += 1 }
            }
            return Double(reds) / Double(max(samples, 1))
        }
        sw.state = .on      // knob at the right → sample the LEFT of the track
        XCTAssertGreaterThan(try redShare(0.22), 0.8, "on: the track is the palette accent")
        sw.state = .off     // knob at the left → sample the RIGHT
        XCTAssertLessThan(try redShare(0.78), 0.1, "off: a lifted surface, not the accent")
    }
}
