//
//  SharedSymbolTests.swift
//  AppKitViewsTests
//
//  One image per symbol name, however often it is asked for.
//
//  Created by David Sherlock on 11/17/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import XCTest
@testable import AppKitViews

@MainActor final class SharedSymbolTests: XCTestCase {
    func testTheSameNameIsTheSameImageAndAnotherNameIsAnother() throws {
        let first = try XCTUnwrap(NSImage.sharedSymbol("doc.text"))
        XCTAssertTrue(NSImage.sharedSymbol("doc.text") === first, "asked again, the image is not built again")
        let other = try XCTUnwrap(NSImage.sharedSymbol("folder"))
        XCTAssertFalse(other === first)
        XCTAssertTrue(first.isTemplate, "a symbol, so an image view can tint it")
    }

    func testANameThatIsNoSymbolIsNilEveryTime() {
        XCTAssertNil(NSImage.sharedSymbol("no.such.symbol.anywhere"))
        XCTAssertNil(NSImage.sharedSymbol("no.such.symbol.anywhere"))
    }
}
