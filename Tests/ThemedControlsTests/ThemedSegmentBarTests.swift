//
//  ThemedSegmentBarTests.swift
//  ThemedControlsTests
//
//  Tests for the segment bar's content plan: what fits in a segment of a given width.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `ThemedSegmentBar.content(for:width:)`: wide segments show symbol and text, narrow
/// ones degrade to the symbol, and the bar redraws while resized.
@MainActor
final class ThemedSegmentBarTests: XCTestCase {

    private let font = NSFont.systemFont(ofSize: 11, weight: .medium)
    private func width(_ s: String) -> CGFloat { ceil((s as NSString).size(withAttributes: [.font: font]).width) }

    private final class Counter: NSObject {
        var fired = 0
        @objc func fire(_ sender: Any?) { fired += 1 }
    }

    /// VoiceOver sees one radio button per segment, named, the selected one valued 1.
    func testSegmentsAreVoiceOverRadioButtonsThatPress() {
        let bar = ThemedSegmentBar(labels: ["All", "30d", "7d"])
        bar.frame = NSRect(x: 0, y: 0, width: 180, height: 24)
        let counter = Counter()
        bar.target = counter; bar.action = #selector(Counter.fire(_:))
        XCTAssertEqual(bar.accessibilityRole(), .radioGroup)
        let kids = (bar.accessibilityChildren() ?? []).compactMap { $0 as? NSAccessibilityElement }
        XCTAssertEqual(kids.map { $0.accessibilityLabel() ?? "" }, ["All", "30d", "7d"])
        XCTAssertEqual(kids.map { $0.accessibilityValue() as? Int ?? -1 }, [1, 0, 0])
        guard kids.count == 3 else { return XCTFail("no segment children — VoiceOver sees an unlabeled blob") }
        XCTAssertTrue(kids[2].accessibilityPerformPress())
        XCTAssertEqual(bar.selectedSegment, 2)
        XCTAssertEqual(counter.fired, 1)
        _ = kids[2].accessibilityPerformPress()
        XCTAssertEqual(counter.fired, 1, "pressing the selected segment again is a no-op")
        XCTAssertEqual(bar.accessibilityValue() as? String, "7d")
    }

    /// A momentary bar fires on every press, keeps no selection and reports the segment; a
    /// disabled segment, or a disabled bar, ignores the press.
    func testMomentaryAndDisabledSegments() {
        let bar = ThemedSegmentBar(labels: ["Add", "Remove"], symbols: ["plus", "minus"])
        bar.isMomentary = true
        bar.symbolsOnly = true
        let counter = Counter()
        bar.target = counter; bar.action = #selector(Counter.fire(_:))
        bar.select(1); bar.select(1); bar.select(0)
        XCTAssertEqual(counter.fired, 3, "every press fires, the same segment twice included")
        XCTAssertEqual(bar.clickedSegment, 0)
        XCTAssertEqual(bar.selectedSegment, 0, "a momentary bar never moves its selection")
        XCTAssertEqual(bar.intrinsicContentSize.width, 64, "symbols only: two 32-pt segments")
        bar.setEnabled(false, forSegment: 1)
        bar.select(1)
        XCTAssertEqual(counter.fired, 3, "a disabled segment ignores the press")
        XCTAssertFalse(bar.isEnabled(forSegment: 1))
        bar.setEnabled(true, forSegment: 1)
        bar.isEnabled = false
        bar.select(1)
        XCTAssertEqual(counter.fired, 3, "a disabled bar ignores the press")
        bar.isEnabled = true
        bar.select(1)
        XCTAssertEqual(counter.fired, 4)
        let kids = (bar.accessibilityChildren() ?? []).compactMap { $0 as? NSAccessibilityElement }
        XCTAssertEqual(kids.map { $0.accessibilityLabel() ?? "" }, ["Add", "Remove"], "VoiceOver still reads the labels")
    }

    /// The arrow keys move the selection and fire, and stop at the ends.
    func testArrowKeysMoveTheSelection() throws {
        let bar = ThemedSegmentBar(labels: ["A", "B", "C"])
        let counter = Counter()
        bar.target = counter; bar.action = #selector(Counter.fire(_:))
        func key(_ code: UInt16) throws -> NSEvent {
            try XCTUnwrap(
                NSEvent.keyEvent(
                    with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0,
                    context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: code))
        }
        bar.keyDown(with: try key(124)); bar.keyDown(with: try key(124)); bar.keyDown(with: try key(124))
        XCTAssertEqual(bar.selectedSegment, 2, "→ ×3 from A stops at C")
        XCTAssertEqual(counter.fired, 2)
        bar.keyDown(with: try key(123))
        XCTAssertEqual(bar.selectedSegment, 1)
        XCTAssertEqual(counter.fired, 3)
    }

    func testTheBarRedrawsWhileResized() {
        XCTAssertEqual(ThemedSegmentBar(labels: ["A"]).layerContentsRedrawPolicy, .duringViewResize)
    }

    func testWideSegmentsShowSymbolAndText() {
        let bar = ThemedSegmentBar(labels: ["All", "Prompts", "Commands"], symbols: ["square.grid.2x2", "text.bubble", "terminal"])
        let plan = bar.content(for: 2, width: 140)
        XCTAssertEqual(plan.symbol, "terminal"); XCTAssertEqual(plan.text, "Commands")
    }

    func testNarrowSegmentsKeepTheSymbolAndDropTheText() {
        let bar = ThemedSegmentBar(labels: ["All", "Prompts", "Commands"], symbols: ["square.grid.2x2", "text.bubble", "terminal"])
        let plan = bar.content(for: 2, width: 60)
        XCTAssertEqual(plan.symbol, "terminal"); XCTAssertEqual(plan.text, "")
        XCTAssertEqual(bar.content(for: 0, width: 60).text, "All", "a short label still fits")
    }

    func testTextOnlySegmentsTruncateWithAnEllipsis() {
        let bar = ThemedSegmentBar(labels: ["Today", "This week", "This month"])
        let plan = bar.content(for: 2, width: 50)
        XCTAssertTrue(plan.text.hasSuffix("…")); XCTAssertLessThanOrEqual(width(plan.text), 50 - 12)
    }

    func testEveryPlanFitsItsSegment() {
        let bar = ThemedSegmentBar(labels: ["All", "Prompts", "Commands"], symbols: ["square.grid.2x2", "text.bubble", "terminal"])
        for w in stride(from: 20, through: 200, by: 10) {
            for i in 0..<3 {
                let plan = bar.content(for: i, width: CGFloat(w))
                let need = width(plan.text) + (plan.symbol == nil ? 0 : (plan.text.isEmpty ? 14 : 18))
                XCTAssertLessThanOrEqual(need, CGFloat(w) - 12 + 0.5, "width \(w) segment \(i): \(plan)")
            }
        }
    }

    func testEqualWidthFramesSpanTheBar() {
        let bar = ThemedSegmentBar(labels: ["A", "B", "C"]); bar.fillsWidth = true
        bar.frame = NSRect(x: 0, y: 0, width: 300, height: 28)
        let frames = bar.frames()
        XCTAssertEqual(frames.map(\.width), [100, 100, 100]); XCTAssertEqual(frames.last?.maxX, 300)
    }
}
