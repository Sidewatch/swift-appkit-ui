//
//  StepFlowTests.swift
//  ThemedControlsTests
//
//  `StepFlow`: Continue walks to the end and finishes after the last, Back stops at the first,
//  Skip finishes from anywhere, and nothing moves once finished.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `StepFlow`'s moves.
final class StepFlowTests: XCTestCase {

    func testContinueWalksEveryStepAndFinishesAfterTheLast() {
        var flow = StepFlow(count: 3)
        XCTAssertTrue(flow.isFirst)
        XCTAssertFalse(flow.isLast)
        flow.advance()
        flow.advance()
        XCTAssertEqual(flow.index, 2)
        XCTAssertTrue(flow.isLast)
        XCTAssertNil(flow.ending, "the last step is showing, not finished")
        flow.advance()
        XCTAssertEqual(flow.ending, .completed)
        XCTAssertEqual(flow.index, 2, "finishing does not run past the last step")
    }

    func testBackStopsAtTheFirstStep() {
        var flow = StepFlow(count: 3)
        flow.back()
        XCTAssertEqual(flow.index, 0)
        flow.advance()
        flow.back()
        XCTAssertEqual(flow.index, 0)
        XCTAssertNil(flow.ending)
    }

    func testSkipFinishesFromAnyStep() {
        var first = StepFlow(count: 4)
        first.skip()
        XCTAssertEqual(first.ending, .skipped)
        var middle = StepFlow(count: 4)
        middle.advance()
        middle.skip()
        XCTAssertEqual(middle.ending, .skipped)
        XCTAssertEqual(middle.index, 1)
    }

    func testNothingMovesOnceFinished() {
        var flow = StepFlow(count: 2)
        flow.skip()
        flow.advance()
        flow.back()
        XCTAssertEqual(flow.ending, .skipped, "a skipped guide is not completed by a late Continue")
        XCTAssertEqual(flow.index, 0)
        var done = StepFlow(count: 2)
        done.advance()
        done.advance()
        done.back()
        XCTAssertEqual(done.ending, .completed)
        XCTAssertEqual(done.index, 1)
    }

    func testAOneStepGuideIsFirstAndLastAndACountBelowOneIsOne() {
        var one = StepFlow(count: 1)
        XCTAssertTrue(one.isFirst && one.isLast)
        one.advance()
        XCTAssertEqual(one.ending, .completed)
        XCTAssertEqual(StepFlow(count: 0).count, 1)
    }
}
