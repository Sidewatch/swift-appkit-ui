//
//  CenteringClipViewTests.swift
//  AppKitViewsTests
//
//  A document smaller than its viewport sits in the middle, not the corner.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import AppKitViews

@MainActor final class CenteringClipViewTests: XCTestCase {
    private func scroll(viewport: NSSize, document: NSSize) -> NSScrollView {
        let scroll = NSScrollView(frame: NSRect(origin: .zero, size: viewport))
        scroll.contentView = CenteringClipView()
        scroll.documentView = NSView(frame: NSRect(origin: .zero, size: document))
        scroll.layoutSubtreeIfNeeded()
        return scroll
    }

    func testASmallerDocumentIsCentredOnBothAxes() {
        let scroll = self.scroll(viewport: NSSize(width: 400, height: 300),
                                 document: NSSize(width: 100, height: 50))
        let origin = scroll.contentView.bounds.origin
        XCTAssertEqual(origin.x, (100 - 400) / 2, accuracy: 0.5)
        XCTAssertEqual(origin.y, (50 - 300) / 2, accuracy: 0.5)
    }

    /// Mixed is the real case: a wide, short image in a tall pane.
    func testOnlyTheAxisWithRoomIsCentred() {
        let scroll = self.scroll(viewport: NSSize(width: 200, height: 400),
                                 document: NSSize(width: 800, height: 50))
        let origin = scroll.contentView.bounds.origin
        XCTAssertEqual(origin.x, 0, accuracy: 0.5, "a document wider than the viewport is not centred")
        XCTAssertEqual(origin.y, (50 - 400) / 2, accuracy: 0.5)
    }

    func testADocumentBiggerThanTheViewportScrollsNormally() {
        let scroll = self.scroll(viewport: NSSize(width: 200, height: 200),
                                 document: NSSize(width: 1000, height: 1000))
        XCTAssertEqual(scroll.contentView.bounds.origin, .zero)
    }

    func testWithNoDocumentTheDefaultConstraintStands() {
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
        scroll.contentView = CenteringClipView()
        scroll.layoutSubtreeIfNeeded()
        XCTAssertEqual(scroll.contentView.bounds.origin, .zero)
    }
}
