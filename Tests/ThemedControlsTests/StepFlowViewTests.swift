//
//  StepFlowViewTests.swift
//  ThemedControlsTests
//
//  `StepFlowView`: each page under its own heading, the footer named for the step (no Back on
//  the first, Done and no Skip on the last), Return and Escape wired, and the end reported once.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `StepFlowView`.
@MainActor
final class StepFlowViewTests: XCTestCase {
    private func page(_ tag: Int) -> NSViewController {
        let controller = NSViewController()
        let view = NSView()
        view.identifier = NSUserInterfaceItemIdentifier("page-\(tag)")
        controller.view = view
        return controller
    }

    private func guide(_ count: Int) -> StepFlowView {
        StepFlowView(
            steps: (0..<count).map { StepFlowStep(title: "Title \($0)", subtitle: "Sub \($0)", symbol: "star", content: page($0)) })
    }

    func testAPageFillsThePageWidthAndShowsItsSymbol() {
        let view = guide(2)
        view.layoutSubtreeIfNeeded()
        XCTAssertEqual(view.pageFrameForTesting.width, StepFlowView.pageWidth, accuracy: 0.5)
        XCTAssertEqual(view.pageFrameForTesting.minX, StepFlowView.margin, accuracy: 0.5, "the same margin both sides")
        XCTAssertTrue(view.tileShownForTesting)
        XCTAssertGreaterThan(view.titleFrameForTesting.minX, StepFlowView.margin + 40, "beside the tile")
        let plain = StepFlowView(steps: [StepFlowStep(title: "T", subtitle: "S", content: page(0))])
        plain.layoutSubtreeIfNeeded()
        XCTAssertFalse(plain.tileShownForTesting)
        XCTAssertEqual(
            plain.titleFrameForTesting.minX, StepFlowView.margin, accuracy: 2.5,
            "no tile: the heading at the margin (a label frame sits 2 pt out from its alignment edge)")
    }

    func testEachPageShowsUnderItsOwnHeading() {
        let view = guide(3)
        var shown: [Int] = []
        view.onStepShown = { shown.append($0) }
        XCTAssertEqual(view.titleForTesting, "Title 0")
        XCTAssertEqual(view.pageViewForTesting?.identifier?.rawValue, "page-0")
        view.goForward()
        XCTAssertEqual(view.titleForTesting, "Title 1")
        XCTAssertEqual(view.pageViewForTesting?.identifier?.rawValue, "page-1")
        XCTAssertEqual(view.pageViewForTesting?.superview?.subviews.count, 1, "the previous page is taken down")
        view.goBack()
        XCTAssertEqual(view.titleForTesting, "Title 0")
        XCTAssertEqual(shown, [1, 0])
    }

    func testTheFooterIsNamedForTheStep() {
        let view = guide(3)
        XCTAssertFalse(view.backShownForTesting, "no Back on the first page")
        XCTAssertTrue(view.skipShownForTesting)
        XCTAssertEqual(view.continueTitleForTesting, "Continue")
        XCTAssertEqual(view.progressForTesting, "Step 1 of 3")
        view.goForward()
        XCTAssertTrue(view.backShownForTesting)
        XCTAssertEqual(view.progressForTesting, "Step 2 of 3")
        view.goForward()
        XCTAssertEqual(view.continueTitleForTesting, "Done", "the last page's Continue finishes")
        XCTAssertFalse(view.skipShownForTesting, "nothing is left to skip on the last page")
        XCTAssertEqual(view.progressForTesting, "Step 3 of 3")
    }

    func testReturnContinuesAndEscapeSkips() {
        let keys = guide(2).keyEquivalentsForTesting
        XCTAssertEqual(keys.continue, "\r")
        XCTAssertEqual(keys.skip, "\u{1b}")
    }

    func testTheEndIsReportedOnceWithHowItEnded() {
        let completed = guide(2)
        var endings: [StepFlow.Ending] = []
        completed.onFinish = { endings.append($0) }
        completed.goForward()
        XCTAssertTrue(endings.isEmpty)
        completed.goForward()
        completed.goForward()
        XCTAssertEqual(endings, [.completed])

        let skipped = guide(3)
        var skippedEndings: [StepFlow.Ending] = []
        skipped.onFinish = { skippedEndings.append($0) }
        skipped.goForward()
        skipped.skip()
        skipped.skip()
        XCTAssertEqual(skippedEndings, [.skipped])
    }
}
