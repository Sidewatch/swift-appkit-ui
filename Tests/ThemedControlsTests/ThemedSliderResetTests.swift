//
//  ThemedSliderResetTests.swift
//  ThemedControlsTests
//
//  `ThemedSlider`'s double-click reset: back to the default value with the action sent, and
//  nothing for a slider that has no default.
//
//  Created by David Sherlock on 10/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `ThemedSlider`'s double-click reset.
@MainActor
final class ThemedSliderResetTests: XCTestCase {
    private final class Recorder: NSObject {
        var values: [Double] = []
        @objc func changed(_ sender: NSSlider) { values.append(sender.doubleValue) }
    }

    override func setUp() {
        super.setUp()
        _ = NSApplication.shared  // a control's action is delivered through the app
    }

    private func doubleClick(on slider: NSSlider) throws -> NSEvent {
        try XCTUnwrap(
            NSEvent.mouseEvent(
                with: .leftMouseDown, location: NSPoint(x: 10, y: 10), modifierFlags: [], timestamp: 0, windowNumber: 0,
                context: nil, eventNumber: 0, clickCount: 2, pressure: 1))
    }

    func testADoubleClickRestoresTheDefaultAndSendsTheAction() throws {
        let recorder = Recorder()
        let slider = ThemedSlider(frame: NSRect(x: 0, y: 0, width: 150, height: 24))
        slider.configureAsSettingsValue(min: 9, max: 32, default: 13, ticks: 6, target: recorder, action: #selector(Recorder.changed(_:)))
        slider.doubleValue = 24
        slider.mouseDown(with: try doubleClick(on: slider))
        XCTAssertEqual(slider.doubleValue, 13)
        XCTAssertEqual(recorder.values, [13], "the action is sent once, with the default")
    }

    func testASliderWithNoDefaultIsLeftAlone() {
        let recorder = Recorder()
        let slider = ThemedSlider(frame: NSRect(x: 0, y: 0, width: 150, height: 24))
        slider.configureAsSettingsValue(min: 0, max: 10, ticks: 5, target: recorder, action: #selector(Recorder.changed(_:)))
        slider.doubleValue = 7
        XCTAssertFalse(slider.resetToDefault())
        XCTAssertEqual(slider.doubleValue, 7)
        XCTAssertTrue(recorder.values.isEmpty)
    }
}
