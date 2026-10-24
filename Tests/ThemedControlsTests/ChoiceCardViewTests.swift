//
//  ChoiceCardViewTests.swift
//  ThemedControlsTests
//
//  `ChoiceCardView`: a click, Space and VoiceOver's press all pick it, picking rings it in the
//  accent, and VoiceOver reads a radio button with its state.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `ChoiceCardView`.
@MainActor
final class ChoiceCardViewTests: XCTestCase {
    private func card() -> ChoiceCardView {
        ChoiceCardView(title: "Read code", detail: "Just the editor.", symbol: "book", width: 300)
    }

    func testAClickInsideSpaceAndVoiceOversPressPickIt() throws {
        let view = card()
        var picks = 0
        view.onPick = { picks += 1 }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 200), styleMask: [], backing: .buffered, defer: true)
        window.contentView?.addSubview(view)
        view.frame = NSRect(x: 10, y: 10, width: 300, height: 80)
        func mouseUp(at point: NSPoint) throws -> NSEvent {
            try XCTUnwrap(
                NSEvent.mouseEvent(
                    with: .leftMouseUp, location: view.convert(point, to: nil), modifierFlags: [], timestamp: 0,
                    windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 0))
        }
        view.mouseUp(with: try mouseUp(at: NSPoint(x: 150, y: 40)))
        XCTAssertEqual(picks, 1)
        view.mouseUp(with: try mouseUp(at: NSPoint(x: 900, y: 40)))
        XCTAssertEqual(picks, 1, "a press dragged off the card is not a pick")
        let space = try XCTUnwrap(
            NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber, context: nil,
                characters: " ", charactersIgnoringModifiers: " ", isARepeat: false, keyCode: 49))
        view.keyDown(with: space)
        XCTAssertEqual(picks, 2)
        XCTAssertTrue(view.accessibilityPerformPress())
        XCTAssertEqual(picks, 3)
    }

    func testPickingRingsItInTheAccent() {
        let view = card()
        XCTAssertNotEqual(view.ring.color, ThemedControls.palette.accent)
        view.isPicked = true
        XCTAssertEqual(view.ring.color, ThemedControls.palette.accent)
        XCTAssertEqual(view.ring.width, 2)
    }

    func testVoiceOverReadsARadioButtonWithItsState() {
        let view = card()
        XCTAssertEqual(view.accessibilityRole(), .radioButton)
        XCTAssertEqual(view.accessibilityLabel(), "Read code")
        XCTAssertEqual(view.accessibilityValue() as? Int, 0)
        view.isPicked = true
        XCTAssertEqual(view.accessibilityValue() as? Int, 1)
    }
}
