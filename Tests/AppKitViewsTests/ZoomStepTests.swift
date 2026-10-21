//
//  ZoomStepTests.swift
//  AppKitViewsTests
//
//  Zoom steps, the fit scale, and a scroll view fitting the same way however far it was zoomed.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import AppKitViews

/// `ZoomStep` and `NSScrollView`'s zoom helpers.
@MainActor
final class ZoomStepTests: XCTestCase {
    func testStepsAreClampedToTheRange() {
        XCTAssertEqual(ZoomStep.next(1, .in, in: 0.1...8), 1.25)
        XCTAssertEqual(ZoomStep.next(1, .out, in: 0.1...8), 0.8)
        XCTAssertEqual(ZoomStep.next(7, .in, in: 0.1...8), 8)
        XCTAssertEqual(ZoomStep.next(0.11, .out, in: 0.1...8), 0.1)
        XCTAssertNil(ZoomStep.next(1, .actual, in: 0.1...8))
    }

    func testTheFitScaleFitsTheTighterSideAndOnlyEnlargesWhenAllowed() {
        XCTAssertEqual(
            ZoomStep.fitScale(content: CGSize(width: 2000, height: 1000), viewport: CGSize(width: 500, height: 500), allowEnlarge: false),
            0.25)
        XCTAssertEqual(
            ZoomStep.fitScale(content: CGSize(width: 100, height: 50), viewport: CGSize(width: 500, height: 500), allowEnlarge: false), 1)
        XCTAssertEqual(
            ZoomStep.fitScale(content: CGSize(width: 100, height: 50), viewport: CGSize(width: 500, height: 500), allowEnlarge: true), 5)
        XCTAssertNil(ZoomStep.fitScale(content: .zero, viewport: CGSize(width: 1, height: 1), allowEnlarge: true))
    }

    /// ⌘0 after zooming in lands on the SAME fit every time: the viewport is measured unscaled.
    func testFittingAfterZoomingInIsStable() {
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        scroll.allowsMagnification = true
        scroll.minMagnification = 0.05
        scroll.maxMagnification = 8
        scroll.documentView = NSView(frame: NSRect(x: 0, y: 0, width: 1600, height: 1200))
        let content = CGSize(width: 1600, height: 1200)
        scroll.magnification = 2
        scroll.fitMagnification(to: content, allowEnlarge: false)
        let first = scroll.magnification
        scroll.fitMagnification(to: content, allowEnlarge: false)
        XCTAssertEqual(first, 0.25, accuracy: 0.001, "400 × 300 over 1600 × 1200")
        XCTAssertEqual(scroll.magnification, first, accuracy: 0.001, "the second press changes nothing")
    }

    /// With legacy scrollers, the fitted content fits the area they leave — so they hide — and the fit is the
    /// same whether they show at the moment or not.
    func testAFitWithLegacyScrollersFitsTheAreaTheyLeaveWhateverTheyShowNow() {
        func fitted(scrollersShowing: Bool, startingAt start: CGFloat = 2) -> (scale: CGFloat, area: CGSize) {
            let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 895, height: 686))
            scroll.scrollerStyle = .legacy
            scroll.hasVerticalScroller = true
            scroll.hasHorizontalScroller = true
            scroll.autohidesScrollers = !scrollersShowing
            scroll.allowsMagnification = true
            scroll.minMagnification = 0.05
            scroll.maxMagnification = 8
            scroll.documentView = NSView(frame: NSRect(x: 0, y: 0, width: 4000, height: 3000))
            scroll.magnification = start
            scroll.tile()  // the scrollers show or hide for the current magnification
            scroll.fitMagnification(to: CGSize(width: 4000, height: 3000), allowEnlarge: false)
            return (scroll.magnification, scroll.fittingContentSize)
        }
        let shown = fitted(scrollersShowing: true), hidden = fitted(scrollersShowing: false)
        // Already small enough that the scrollers hid: the fit must still leave room for them.
        let fromFitted = fitted(scrollersShowing: false, startingAt: 0.1)
        XCTAssertEqual(fromFitted.scale, shown.scale, accuracy: 0.0001, "the same fit from a state with the scrollers hidden")
        XCTAssertEqual(shown.scale, hidden.scale, accuracy: 0.0001, "the scroller state at the moment does not matter")
        XCTAssertLessThanOrEqual(4000 * shown.scale, shown.area.width + 0.001)
        XCTAssertLessThanOrEqual(3000 * shown.scale, shown.area.height + 0.001, "it fits beside the scrollers, so they can hide")
        XCTAssertLessThan(shown.area.width, 895, "legacy scrollers take room")
    }
}
