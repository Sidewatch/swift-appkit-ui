//
//  EmptyStateViewTests.swift
//  ThemedControlsTests
//
//  The empty state's actions: a primary button and any number of secondary ones beneath it,
//  each click reaching its own handler, and a later state hiding what it does not name.
//
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

@MainActor
final class EmptyStateViewTests: XCTestCase {
    /// The visible buttons, top to bottom, as laid out in a window.
    private func visibleButtons(_ state: EmptyStateView) -> [NSButton] {
        state.layoutSubtreeIfNeeded()
        func all(_ v: NSView) -> [NSView] { v.subviews + v.subviews.flatMap(all) }
        return all(state).compactMap { $0 as? NSButton }.filter { !$0.isHiddenOrHasHiddenAncestor }
            .sorted { state.convert($0.bounds, from: $0).midY > state.convert($1.bounds, from: $1).midY }
    }

    private func host(_ state: EmptyStateView) -> NSWindow {
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 320, height: 400), styleMask: [.titled], backing: .buffered, defer: false)
        w.contentView!.addSubview(state)
        NSLayoutConstraint.activate([
            state.centerXAnchor.constraint(equalTo: w.contentView!.centerXAnchor),
            state.centerYAnchor.constraint(equalTo: w.contentView!.centerYAnchor),
        ])
        return w
    }

    func testEverySecondaryActionShowsInOrderAndReachesItsOwnHandler() {
        let state = EmptyStateView(symbol: "folder", title: "No Folder Open", subtitle: "Open one.")
        let window = host(state)
        var clicked: [String] = []
        state.show(
            symbol: "folder", title: "No Folder Open", subtitle: "Open one.",
            buttonTitle: "Open Folder…", action: { clicked.append("open") },
            secondary: [("New Project…", { clicked.append("new") }), ("Clone Repository…", { clicked.append("clone") })])
        let buttons = visibleButtons(state)
        XCTAssertEqual(buttons.map(\.title), ["Open Folder…", "New Project…", "Clone Repository…"])
        for b in buttons { b.performClick(nil) }
        XCTAssertEqual(clicked, ["open", "new", "clone"])
        XCTAssertNotNil(window)
    }

    func testALaterStateHidesTheActionsItDoesNotName() {
        let state = EmptyStateView(symbol: "folder", title: "", subtitle: "")
        let window = host(state)
        var clicked: [String] = []
        state.show(
            symbol: "folder", title: "A", subtitle: "", buttonTitle: "One", action: {},
            secondary: [("Two", { clicked.append("two") }), ("Three", { clicked.append("three") })])
        state.show(symbol: "folder", title: "B", subtitle: "", secondaryTitle: "Only", secondaryAction: { clicked.append("only") })
        XCTAssertEqual(visibleButtons(state).map(\.title), ["Only"], "no primary, one secondary")
        visibleButtons(state).first?.performClick(nil)
        XCTAssertEqual(clicked, ["only"])
        state.show(symbol: "folder", title: "C", subtitle: "")
        XCTAssertEqual(visibleButtons(state), [], "a state with no actions shows no buttons")
        XCTAssertNotNil(window)
    }
}
