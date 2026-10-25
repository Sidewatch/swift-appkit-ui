//
//  DockPositionPickerTests.swift
//  ThemedControlsTests
//
//  `DockPositionPicker`: one tile per position, a pick rings it and reports it, the panel drawn
//  where its position says (beside or under the content, never under the sidebar).
//
//  Created by David Sherlock on 10/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `DockPositionPicker` and `DockPositionTile`.
@MainActor
final class DockPositionPickerTests: XCTestCase {
    private func picker() -> DockPositionPicker {
        let view = DockPositionPicker(width: 600) { "\($0)" }
        view.layoutSubtreeIfNeeded()
        return view
    }

    func testOneTilePerPositionInReadingOrderAndThePickRingedAndReported() {
        let view = picker()
        XCTAssertEqual(view.tiles.map(\.position), [.leading, .bottom, .trailing])
        XCTAssertEqual(view.tiles.map { $0.accessibilityLabel() }, ["leading", "bottom", "trailing"])
        XCTAssertEqual(view.tiles.map(\.isPicked), [false, true, false], "bottom until the host says otherwise")
        var picks: [DockPosition] = []
        view.onPick = { picks.append($0) }
        XCTAssertTrue(view.tiles[2].accessibilityPerformPress())
        XCTAssertEqual(picks, [.trailing])
        XCTAssertEqual(view.tiles.map(\.isPicked), [false, false, true], "the pick moves the ring")
        XCTAssertEqual(view.tiles[2].ring.color, ThemedControls.palette.accent)
        view.selected = .leading
        XCTAssertEqual(view.tiles.map(\.isPicked), [true, false, false])
        XCTAssertEqual(picks, [.trailing], "the host setting it is not a pick")
    }

    func testThePanelSitsWhereItsPositionSays() {
        let view = picker()
        let (leading, bottom, trailing) = (view.tiles[0], view.tiles[1], view.tiles[2])
        let window = leading.windowRect
        XCTAssertGreaterThan(leading.panelRect.minX, window.minX + 10, "beside the content, after the sidebar")
        XCTAssertLessThan(leading.panelRect.midX, window.midX)
        XCTAssertEqual(trailing.panelRect.maxX, trailing.windowRect.maxX, accuracy: 0.5, "at the window's trailing edge")
        XCTAssertEqual(bottom.panelRect.minY, bottom.windowRect.minY, accuracy: 0.5, "at the bottom")
        XCTAssertLessThan(bottom.panelRect.height, bottom.windowRect.height / 2)
        XCTAssertGreaterThan(bottom.panelRect.minX, bottom.windowRect.minX + 10, "under the content, not the sidebar")
    }

    func testTurningThePanelOffReachesEveryTile() {
        let view = picker()
        view.showsPanel = false
        XCTAssertTrue(view.tiles.allSatisfy { !$0.showsPanel })
    }
}
