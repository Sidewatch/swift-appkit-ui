//
//  LoadingStateViewTests.swift
//  ThemedControlsTests
//
//  The loading state: hidden for a fast load, shown once a load outlasts its delay, hidden again
//  when the load ends, and a second begin never restarts the wait.
//
//  Created by David Sherlock on 10/22/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

@MainActor
final class LoadingStateViewTests: XCTestCase {
    /// Runs the main run loop for `seconds`.
    private func spin(_ seconds: TimeInterval) {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds))
    }

    func testAFastLoadNeverShows() {
        let state = LoadingStateView(caption: "Loading changes…")
        state.delay = 0.1
        state.begin()
        XCTAssertTrue(state.isHidden, "not at once")
        state.end()
        spin(0.25)
        XCTAssertTrue(state.isHidden, "a load that ended before the delay never shows")
        XCTAssertFalse(state.isLoading)
    }

    func testASlowLoadShowsAfterTheDelayAndHidesWhenItEnds() {
        let state = LoadingStateView(caption: "Loading changes…")
        state.delay = 0.05
        state.begin()
        XCTAssertTrue(state.isHidden)
        spin(0.2)
        XCTAssertFalse(state.isHidden, "shown once the load outlasts the delay")
        XCTAssertTrue(state.isLoading)
        state.end()
        XCTAssertTrue(state.isHidden, "hidden the moment the load ends")
    }

    func testASecondBeginKeepsTheFirstWait() {
        let state = LoadingStateView(caption: "Reading sound…")
        state.delay = 0.15
        state.begin()
        spin(0.1)
        state.begin()  // a refresh during the same load
        spin(0.1)
        XCTAssertFalse(state.isHidden, "0.2 s after the first begin: the first wait stood")
    }

    func testItCoversItsHostCentredAndStartsHidden() {
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        let host = NSView(frame: parent.bounds)
        parent.addSubview(host)
        let state = LoadingStateView(caption: "Loading changes…")
        state.install(over: host)
        XCTAssertTrue(state.superview === parent && state.isHidden, "a sibling above the host, hidden until a load outlasts the delay")
        XCTAssertEqual(parent.subviews.last, state, "above the host")
    }

    func testTheCaptionCanChange() {
        let state = LoadingStateView(caption: "Loading changes…")
        state.caption = "Reading session…"
        XCTAssertEqual(state.caption, "Reading session…")
    }
}
