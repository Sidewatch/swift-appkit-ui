//
//  EmptyStateViewTests.swift
//  ThemedControlsTests
//
//  The empty state's actions: a primary button and any number of secondary ones beneath it,
//  each click reaching its own handler, and a later state hiding what it does not name; and
//  how it covers a split view's pane.
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

    /// A state over a split view's pane covers the pane without becoming a pane: the split keeps its two panes,
    /// and the state sits centred over the one it was installed over.
    func testAStateOverASplitPaneCoversItWithoutBecomingAPane() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 600), styleMask: [.titled], backing: .buffered, defer: false)
        let split = NSSplitView()
        split.isVertical = false
        let top = NSView(), bottom = NSView()
        split.addArrangedSubview(top)
        split.addArrangedSubview(bottom)
        split.setHoldingPriority(.defaultLow - 1, forSubviewAt: 0)
        split.setHoldingPriority(.defaultLow + 1, forSubviewAt: 1)
        split.translatesAutoresizingMaskIntoConstraints = false
        window.contentView!.addSubview(split)
        NSLayoutConstraint.activate([
            split.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
            split.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor),
            split.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            split.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            bottom.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
        ])
        let state = EmptyStateView(symbol: "folder", title: "Reading…", subtitle: "")
        state.install(over: top)
        state.isHidden = false
        window.contentView!.layoutSubtreeIfNeeded()

        XCTAssertEqual(split.arrangedSubviews, [top, bottom])
        XCTAssertFalse(split.subviews.contains(state))
        let pane = top.convert(top.bounds, to: nil)
        let cover = state.convert(state.bounds, to: nil)
        XCTAssertEqual(cover.midY, pane.midY, accuracy: 1)
        XCTAssertGreaterThan(pane.height, 300, "the pane keeps the room its holding priority gives it")
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
