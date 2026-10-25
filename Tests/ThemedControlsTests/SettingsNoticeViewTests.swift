//
//  SettingsNoticeViewTests.swift
//  ThemedControlsTests
//
//  `SettingsNoticeView`: its text, read by VoiceOver as one line, wrapping inside the card.
//
//  Created by David Sherlock on 10/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `SettingsNoticeView`.
@MainActor
final class SettingsNoticeViewTests: XCTestCase {
    func testItShowsItsTextAsOneAccessibleLineThatWrapsInsideTheCard() {
        let text = String(repeating: "Agent features are off, so the switches below do nothing. ", count: 3)
        let notice = SettingsNoticeView(text)
        let row = SettingsRowView(spanning: notice)
        row.widthAnchor.constraint(equalToConstant: SettingsMetrics.paneWidth).isActive = true
        row.layoutSubtreeIfNeeded()
        XCTAssertEqual(notice.textForTesting, text)
        XCTAssertEqual(notice.accessibilityLabel(), text)
        XCTAssertEqual(notice.accessibilityRole(), .staticText)
        XCTAssertLessThanOrEqual(notice.fittingSize.width, SettingsMetrics.paneWidth, "wraps rather than widening the card")
        XCTAssertGreaterThan(notice.fittingSize.height, 20, "a long notice takes more than one line")
    }
}
