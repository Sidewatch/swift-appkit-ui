//
//  FlowLayoutTests.swift
//  AppKitViewsTests
//
//  Items wrap onto a new line when the width runs out.
//
//  Created by David Sherlock on 9/28/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import XCTest
@testable import AppKitViews

final class FlowLayoutTests: XCTestCase {
    private let pill = CGSize(width: 60, height: 22)

    func testItemsWrapWhenTheWidthRunsOut() {
        let placed = FlowLayout.frames(for: [pill, pill, pill], width: 140, spacing: 6, lineSpacing: 4)
        XCTAssertEqual(placed.frames.map(\.origin), [CGPoint(x: 0, y: 0), CGPoint(x: 66, y: 0), CGPoint(x: 0, y: 26)])
        XCTAssertEqual(placed.height, 48, "two lines of 22 with a 4-point gap")
    }

    func testOneLineWhenEverythingFits() {
        let placed = FlowLayout.frames(for: [pill, pill], width: 126, spacing: 6, lineSpacing: 4)
        XCTAssertEqual(placed.frames.map(\.minY), [0, 0], "60 + 6 + 60 fits exactly")
        XCTAssertEqual(placed.height, 22)
    }

    func testAnItemWiderThanTheLineIsNarrowedToIt() {
        let placed = FlowLayout.frames(for: [pill, CGSize(width: 500, height: 22)], width: 100, spacing: 6, lineSpacing: 4)
        XCTAssertEqual(placed.frames[1], CGRect(x: 0, y: 26, width: 100, height: 22))
    }

    func testNothingTakesNoHeight() {
        XCTAssertEqual(FlowLayout.frames(for: [], width: 100, spacing: 6, lineSpacing: 4).height, 0)
    }

    @MainActor func testTheViewPlacesItsSubviews() {
        let flow = FlowView(frame: NSRect(x: 0, y: 0, width: 140, height: 100))
        flow.spacing = 6
        flow.lineSpacing = 4
        let items = (0..<3).map { _ in FixedSizeView(size: pill) }
        flow.setArrangedViews(items)
        flow.layoutSubtreeIfNeeded()
        XCTAssertEqual(items.map(\.frame.origin), [CGPoint(x: 0, y: 0), CGPoint(x: 66, y: 0), CGPoint(x: 0, y: 26)])
        XCTAssertEqual(flow.contentHeight(forWidth: 140), 48)
        XCTAssertEqual(flow.contentHeight(forWidth: 400), 22, "wider, one line")
    }
}

private final class FixedSizeView: NSView {
    let size: CGSize
    init(size: CGSize) { self.size = size; super.init(frame: .zero) }
    required init?(coder: NSCoder) { fatalError() }
    override var intrinsicContentSize: NSSize { size }
}
