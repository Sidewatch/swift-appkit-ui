//
//  HeadsUpDisplayTests.swift
//  ThemedControlsTests
//
//  The heads-up capsule: one per window, top centre under the title strip, click-through,
//  gone after its dwell.
//
//  Created by David Sherlock on 9/24/26.
//

import XCTest
@testable import ThemedControls

@MainActor
final class HeadsUpDisplayTests: XCTestCase {
    private func window() -> NSWindow {
        NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400), styleMask: [.titled], backing: .buffered, defer: false)
    }

    func testShowsTopCentredClickThroughAndGoesAfterTheDwell() {
        let saved = ThemedControls.reduceMotion
        ThemedControls.reduceMotion = true   // no fades: the state is exact
        defer { ThemedControls.reduceMotion = saved }
        let w = window()
        HeadsUpDisplay.show("Copied format", systemImage: "doc.on.doc", in: w)
        let d = HeadsUpDisplay.showing(in: w)
        XCTAssertNotNil(d)
        let content = w.contentView!
        let layout = content.convert(w.contentLayoutRect, from: nil)
        XCTAssertEqual(d!.frame.midX, layout.midX, accuracy: 1)
        XCTAssertEqual(d!.frame.maxY, layout.maxY - 12, accuracy: 1)
        XCTAssertTrue(content.subviews.last === d, "frontmost")
        XCTAssertEqual(d!.label.stringValue, "Copied format")
        XCTAssertNotNil(d!.icon.image)
        XCTAssertNil(d!.hitTest(NSPoint(x: d!.bounds.midX, y: d!.bounds.midY)), "takes no clicks")
        // A second show reuses the one view and restarts the dwell.
        HeadsUpDisplay.show("Copied path", systemImage: "doc.on.doc", in: w)
        XCTAssertTrue(HeadsUpDisplay.showing(in: w) === d)
        XCTAssertEqual(d!.label.stringValue, "Copied path")
        RunLoop.main.run(until: Date(timeIntervalSinceNow: HeadsUpDisplay.dwell + 0.3))
        XCTAssertNil(HeadsUpDisplay.showing(in: w), "gone after the dwell")
    }

    func testANilWindowShowsNothing() {
        HeadsUpDisplay.show("Copied", systemImage: "doc.on.doc", in: nil)   // must not trap
    }

    func testDifferentiateWithoutColorMirrorsTheWorkspaceUntilSet() {
        let saved = ThemedControls.differentiateWithoutColor
        defer { ThemedControls.differentiateWithoutColor = saved }
        ThemedControls.differentiateWithoutColor = true
        XCTAssertTrue(ThemedControls.differentiateWithoutColor)
        ThemedControls.differentiateWithoutColor = false
        XCTAssertFalse(ThemedControls.differentiateWithoutColor)
    }
}
