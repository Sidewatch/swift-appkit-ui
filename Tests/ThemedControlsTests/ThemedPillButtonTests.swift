//
//  ThemedPillButtonTests.swift
//  ThemedControlsTests
//
//  A disabled pill dims; an enabled one is full strength.
//
//  Created by David Sherlock on 9/18/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `ThemedPillButton`: the disabled state is visible.
@MainActor
final class ThemedPillButtonTests: XCTestCase {
    private func titleAlpha(_ b: ThemedPillButton) -> CGFloat {
        (b.attributedTitle.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor)?.alphaComponent ?? -1
    }

    func testADisabledPillDimsAndAnEnabledOneIsFullStrength() {
        let b = ThemedPillButton(title: "+ Row")
        XCTAssertEqual(titleAlpha(b), 1, accuracy: 0.001)
        b.isEnabled = false
        XCTAssertEqual(titleAlpha(b), 0.4, accuracy: 0.001, "the stock bezel greys out; a bright pill reads as clickable")
        b.isEnabled = true
        XCTAssertEqual(titleAlpha(b), 1, accuracy: 0.001)
    }
}
