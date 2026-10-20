//
//  ThemedSwitchTests.swift
//  ThemedControlsTests
//
//  The switch's contract: the stock track and knob, toggle fires once, a set state is silent, the
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

    /// The paint is the stock switch's, measured from its rendering: the track regular 54 × 24,
    /// small 44 × 20, mini 36 × 17; a capsule knob 32 × 20, 26 × 16, 21 × 13, inset evenly and at
    /// the leading end off, the trailing end on. The footprint is the track.
    func testTrackAndKnobAreTheStockSwitchs() {
        for (size, track, knob) in [
            (NSControl.ControlSize.regular, NSSize(width: 54, height: 24), NSSize(width: 32, height: 20)),
            (.small, NSSize(width: 44, height: 20), NSSize(width: 26, height: 16)),
            (.mini, NSSize(width: 36, height: 17), NSSize(width: 21, height: 13)),
        ] {
            let sw = ThemedSwitch()
            sw.controlSize = size
            XCTAssertEqual(sw.intrinsicContentSize, track, "\(size): the footprint is the track")
            sw.frame = NSRect(origin: .zero, size: sw.intrinsicContentSize)
            XCTAssertEqual(sw.trackRect, sw.bounds, "\(size): the track fills the footprint")
            XCTAssertEqual(sw.knobRect.size, knob, "\(size): the knob")
            let inset = (track.height - knob.height) / 2
            XCTAssertEqual(sw.knobRect.minX, inset, accuracy: 0.01, "\(size): off, the knob at the leading end")
            XCTAssertEqual(sw.knobRect.midY, sw.bounds.midY, accuracy: 0.01, "\(size): centred")
            sw.state = .on  // off screen: no slide
            XCTAssertEqual(sw.knobRect.maxX, track.width - inset, accuracy: 0.01, "\(size): on, the trailing end")
        }
        XCTAssertEqual(ThemedSwitch().intrinsicContentSize, NSSwitch().intrinsicContentSize, "regular is the stock footprint")
    }

    /// A frame larger than the footprint keeps the stock-sized track, centred, instead of stretching it.
    func testALargerFrameKeepsTheTrackSizeCentred() {
        let sw = ThemedSwitch(frame: NSRect(x: 0, y: 0, width: 80, height: 40))
        XCTAssertEqual(sw.trackRect.size, NSSize(width: 54, height: 24))
        XCTAssertEqual(sw.trackRect.midX, 40, accuracy: 0.01)
        XCTAssertEqual(sw.trackRect.midY, 20, accuracy: 0.01)
    }

    /// A header strip wants the small switch: the footprint follows the control size and returns
    /// with it.
    func testTheFootprintFollowsTheControlSize() {
        let sw = ThemedSwitch(frame: .zero)
        let regular = sw.intrinsicContentSize
        sw.controlSize = .small
        XCTAssertEqual(sw.intrinsicContentSize, NSSize(width: 44, height: 20))
        sw.controlSize = .mini
        XCTAssertEqual(sw.intrinsicContentSize, NSSize(width: 36, height: 17))
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
        let host = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100), styleMask: [.titled], backing: .buffered, defer: false)
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
            // Sampled along the TRACK,
            // `side` a fraction of its width, on its centre line.
            let track = sw.trackRect
            let y = Int((sw.bounds.maxY - track.midY) * scale)  // rep rows run top-down
            for px in stride(
                from: Int((track.minX + track.width * (side - 0.08)) * scale), to: Int((track.minX + track.width * (side + 0.08)) * scale),
                by: 1)
            {
                guard let c = rep.colorAt(x: px, y: y)?.usingColorSpace(.sRGB) else { continue }
                samples += 1
                if c.redComponent > 0.6, c.greenComponent < 0.35, c.blueComponent < 0.35 { reds += 1 }
            }
            return Double(reds) / Double(max(samples, 1))
        }
        sw.state = .on  // knob at the right → sample the LEFT of the track
        XCTAssertGreaterThan(try redShare(0.22), 0.8, "on: the track is the palette accent")
        sw.state = .off  // knob at the left → sample the RIGHT
        XCTAssertLessThan(try redShare(0.78), 0.1, "off: a lifted surface, not the accent")
    }
}
