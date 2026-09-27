//
//  ZoomingScrollViewTests.swift
//  AppKitViewsTests
//
//  The wheel zooms on every device, at the pointer, within the magnification range.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import AppKitViews

@MainActor final class ZoomingScrollViewTests: XCTestCase {
    private func makeScroll() -> ZoomingScrollView {
        let scroll = ZoomingScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))
        scroll.contentView = CenteringClipView()
        scroll.documentView = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 800))
        scroll.allowsMagnification = true
        scroll.minMagnification = 0.25
        scroll.maxMagnification = 4
        scroll.magnification = 1
        scroll.layoutSubtreeIfNeeded()
        return scroll
    }

    /// `NSEvent` cannot be built with a scrolling delta, so the event is a stub that reports
    /// one. That is the only input `scrollWheel` reads besides the pointer.
    private final class WheelEvent: NSEvent {
        // swiftlint:disable:next identifier_name
        nonisolated(unsafe) static var deltaY: CGFloat = 0
        nonisolated(unsafe) static var precise = false
        override var scrollingDeltaY: CGFloat { Self.deltaY }
        override var hasPreciseScrollingDeltas: Bool { Self.precise }
        override var locationInWindow: NSPoint { NSPoint(x: 100, y: 100) }
    }

    private func wheel(_ delta: CGFloat, precise: Bool) -> NSEvent {
        WheelEvent.deltaY = delta
        WheelEvent.precise = precise
        return WheelEvent()
    }

    func testADetentedWheelZoomsIn() {
        let scroll = makeScroll()
        scroll.scrollWheel(with: wheel(1, precise: false))
        XCTAssertGreaterThan(scroll.magnification, 1)
    }

    func testADetentedWheelTheOtherWayZoomsOut() {
        let scroll = makeScroll()
        scroll.scrollWheel(with: wheel(-1, precise: false))
        XCTAssertLessThan(scroll.magnification, 1)
    }

    /// Precise deltas must zoom too, not pass to `super`: otherwise a trackpad or Magic Mouse
    /// only scrolls and nothing zooms but pinch.
    func testPreciseTrackpadDeltasZoomToo() {
        let scroll = makeScroll()
        scroll.scrollWheel(with: wheel(40, precise: true))
        XCTAssertGreaterThan(scroll.magnification, 1)
    }

    /// Smooth means small: one trackpad event must not jump the way a detent does.
    func testAPreciseDeltaMovesLessPerUnitThanADetent() {
        let trackpad = makeScroll()
        trackpad.scrollWheel(with: wheel(1, precise: true))
        let mouse = makeScroll()
        mouse.scrollWheel(with: wheel(1, precise: false))
        XCTAssertLessThan(trackpad.magnification - 1, mouse.magnification - 1)
    }

    func testZoomIsHeldInsideTheMagnificationRange() {
        let scroll = makeScroll()
        for _ in 0..<200 { scroll.scrollWheel(with: wheel(3, precise: false)) }
        XCTAssertEqual(scroll.magnification, scroll.maxMagnification, accuracy: 0.0001)
        for _ in 0..<400 { scroll.scrollWheel(with: wheel(-3, precise: false)) }
        XCTAssertEqual(scroll.magnification, scroll.minMagnification, accuracy: 0.0001)
    }

    /// A flicked wheel arrives as one huge delta; without the clamp it would cross the whole
    /// range in a single event.
    func testOneEventCannotCrossTheWholeRange() {
        let scroll = makeScroll()
        scroll.scrollWheel(with: wheel(500, precise: false))
        XCTAssertLessThan(scroll.magnification, scroll.maxMagnification)
    }

    /// A zero delta is handed to `super`, which is the one path that reaches AppKit's own
    /// scrolling — so this case needs a REAL event. A stub `NSEvent` raises "Unrecognized event
    /// type 0" the moment `super` inspects it.
    func testAZeroDeltaChangesNothing() throws {
        let scroll = makeScroll()
        let cg = try XCTUnwrap(
            CGEvent(
                scrollWheelEvent2Source: nil, units: .pixel,
                wheelCount: 1, wheel1: 0, wheel2: 0, wheel3: 0))
        let event = try XCTUnwrap(NSEvent(cgEvent: cg))
        scroll.scrollWheel(with: event)
        XCTAssertEqual(scroll.magnification, 1, accuracy: 0.0001)
    }

    /// Each detent moves the same visual proportion, which is why the step is multiplicative.
    func testTheStepIsProportionalRatherThanAbsolute() {
        let scroll = makeScroll()
        scroll.scrollWheel(with: wheel(1, precise: false))
        let firstRatio = scroll.magnification / 1
        let before = scroll.magnification
        scroll.scrollWheel(with: wheel(1, precise: false))
        XCTAssertEqual(scroll.magnification / before, firstRatio, accuracy: 0.001)
    }
}
