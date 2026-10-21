//
//  FlexVectorTests.swift
//  PaneLayoutTests
//
//  Flex-vector validity, survivors keeping their proportions, and setFlexes refusing a bad vector.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import PaneLayout

/// `FlexVector` and `PaneAxisView.setFlexes`.
@MainActor
final class FlexVectorTests: XCTestCase {
    func testAValidVectorHasOnePositiveSharePerMemberSummingToTheCount() {
        XCTAssertTrue(FlexVector.isValid([1.5, 0.5], count: 2))
        XCTAssertTrue(FlexVector.isValid([1.004, 0.999], count: 2), "within the tolerance")
        XCTAssertFalse(FlexVector.isValid([1, 1, 1], count: 2), "count")
        XCTAssertFalse(FlexVector.isValid([0.5, 0.5], count: 2), "sum")
        XCTAssertFalse(FlexVector.isValid([2, 0], count: 2), "a zero share")
        XCTAssertFalse(FlexVector.isValid([2.5, -0.5], count: 2), "a negative share")
    }

    func testSurvivorsKeepTheirProportions() throws {
        let kept = try XCTUnwrap(FlexVector.keeping([1.5, 1.0, 0.5], at: [0, 1]))
        XCTAssertEqual(kept[0], 1.2, accuracy: 1e-9, "1.5 : 1.0 is still 3 : 2, rescaled to sum to 2")
        XCTAssertEqual(kept[1], 0.8, accuracy: 1e-9)
        XCTAssertTrue(FlexVector.isValid(kept, count: 2))
        XCTAssertNil(FlexVector.keeping([1, 1], at: [0, 5]), "an index out of range")
        XCTAssertNil(FlexVector.keeping([1, 1], at: []))
    }

    func testSetFlexesRefusesAnInvalidVector() {
        let axis = PaneAxisView(orientation: .horizontal)
        axis.setMembers([NSView(), NSView()])
        XCTAssertFalse(axis.setFlexes([0.5, 0.5]), "a wrong sum would trip the invariant")
        XCTAssertEqual(axis.flexes, [1, 1], "the equal shares stay")
        XCTAssertTrue(axis.setFlexes([1.25, 0.75]))
        XCTAssertEqual(axis.flexes, [1.25, 0.75])
    }
}
