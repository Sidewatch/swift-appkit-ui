//
//  SliderSettingsTests.swift
//  ThemedControlsTests
//
//  The Settings value slider's setup and its readout's fixed width.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// `ThemedSlider.configureAsSettingsValue` and `NSTextField.styleAsSliderReadout`.
@MainActor
final class SliderSettingsTests: XCTestCase {
    func testAValueSliderIsContinuousSmallAndReachesEveryValue() {
        let slider = ThemedSlider()
        slider.isContinuous = false  // NSSlider's default is continuous: start from the other state
        slider.configureAsSettingsValue(min: 8, max: 36, ticks: 8, target: nil, action: #selector(NSObject.description))
        XCTAssertEqual(slider.minValue, 8)
        XCTAssertEqual(slider.maxValue, 36)
        XCTAssertTrue(slider.isContinuous)
        XCTAssertEqual(slider.controlSize, .small)
        XCTAssertEqual(slider.numberOfTickMarks, 8)
        XCTAssertFalse(slider.allowsTickMarkValuesOnly, "the ticks are a scale cue, not stops")
        XCTAssertEqual(slider.action, #selector(NSObject.description))
        XCTAssertTrue(slider.constraints.contains { $0.firstAttribute == .width && $0.constant == ThemedSlider.settingsWidth })
    }

    func testAReadoutIsRightAlignedAtAFixedWidth() {
        let label = NSTextField(labelWithString: "")
        label.styleAsSliderReadout(width: 44)
        XCTAssertEqual(label.alignment, .right)
        XCTAssertEqual(label.font?.pointSize, 12)
        XCTAssertTrue(label.constraints.contains { $0.firstAttribute == .width && $0.constant == 44 && $0.relation == .equal })
    }
}
