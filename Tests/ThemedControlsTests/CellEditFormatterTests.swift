//
//  CellEditFormatterTests.swift
//  ThemedControlsTests
//
//  A cell's decoration is drawn, never typed over.
//
//  Created by David Sherlock on 9/25/26.
//

import XCTest
import AppKit
@testable import ThemedControls

final class CellEditFormatterTests: XCTestCase {
    func testWrappedValueDrawsItsDecorationAndEditsWithout() {
        let quotes = CellEditFormatter(prefix: "\"", suffix: "\"")
        XCTAssertEqual(quotes.string(for: "nginx"), "\"nginx\"")
        XCTAssertEqual(quotes.editingString(for: "nginx"), "nginx", "the editor loads the bare value")
        XCTAssertEqual(quotes.string(for: ""), "\"\"")
        let colon = CellEditFormatter(suffix: ":")
        XCTAssertEqual(colon.string(for: "image"), "image:")
        XCTAssertEqual(colon.editingString(for: "image"), "image")
        let plain = CellEditFormatter()
        XCTAssertEqual(plain.string(for: "42"), "42")
        XCTAssertEqual(plain.editingString(for: "42"), "42")
        XCTAssertNil(plain.string(for: 42), "only strings are formatted")
    }

    func testSubstituteHidesTheValueButNotFromTheEditor() {
        let masked = CellEditFormatter(substitute: "••••••••")
        XCTAssertEqual(masked.string(for: "s3cret"), "••••••••")
        XCTAssertEqual(masked.editingString(for: "s3cret"), "s3cret", "you cannot type over what you cannot see")
    }

    func testTypedTextComesBackExactly() {
        let quotes = CellEditFormatter(prefix: "\"", suffix: "\"")
        var object: AnyObject?
        XCTAssertTrue(quotes.getObjectValue(&object, for: "a \"quoted\" value", errorDescription: nil))
        XCTAssertEqual(object as? String, "a \"quoted\" value", "the formatter never re-decorates what was typed")
    }

    /// The bug the type exists for: a field built with the formatter hands back the BARE value
    /// after an edit that typed nothing, so a caller comparing it to the value sees no change.
    func testAFieldRoundTripsWithoutGainingItsDecoration() {
        let field = NSTextField(labelWithString: "")
        field.formatter = CellEditFormatter(prefix: "\"", suffix: "\"")
        field.objectValue = "nginx"
        XCTAssertEqual(field.stringValue, "\"nginx\"", "what the row draws")
        XCTAssertEqual(field.objectValue as? String, "nginx", "what an edit reads back")
    }
}
