//
//  NSColorContrastTests.swift
//  AppKitViewsTests
//
//  WCAG luminance and contrast against the published reference values.
//
//  Created by David Sherlock on 10/13/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import AppKitViews

final class NSColorContrastTests: XCTestCase {
    private func hex(_ s: String) -> NSColor { NSColor(hex: s)! }

    func testBlackOnWhiteIsTwentyOne() {
        XCTAssertEqual(hex("#000000").contrastRatio(with: hex("#ffffff")), 21, accuracy: 0.001)
        XCTAssertEqual(hex("#ffffff").contrastRatio(with: hex("#000000")), 21, accuracy: 0.001, "order does not matter")
    }

    func testAColourAgainstItselfIsOne() {
        XCTAssertEqual(hex("#635bff").contrastRatio(with: hex("#635bff")), 1, accuracy: 0.0001)
    }

    func testKnownPairs() {
        // WebAIM's reference values: #777777 on white is 4.48:1, #0000ff on white 8.59:1.
        XCTAssertEqual(hex("#777777").contrastRatio(with: hex("#ffffff")), 4.48, accuracy: 0.01)
        XCTAssertEqual(hex("#0000ff").contrastRatio(with: hex("#ffffff")), 8.59, accuracy: 0.01)
    }

    func testANearBackgroundColourReadsAsLowContrast() {
        // zinc-900 on a One Dark background: the case that hid a colour underline.
        XCTAssertLessThan(hex("#18181b").contrastRatio(with: hex("#282c34")), 1.5)
        XCTAssertGreaterThan(hex("#16a34a").contrastRatio(with: hex("#282c34")), 3)
    }
}
