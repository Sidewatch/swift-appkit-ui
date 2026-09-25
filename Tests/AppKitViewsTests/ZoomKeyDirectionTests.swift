//
//  ZoomKeyDirectionTests.swift
//  AppKitViewsTests
//
//  The zoom-key map, and the keys it must NOT claim.
//
//  Created by David Sherlock on 9/26/26.
//

import XCTest
@testable import AppKitViews

final class ZoomKeyDirectionTests: XCTestCase {
    func testTheZoomMenuConvention() {
        XCTAssertEqual(ZoomKeyDirection(keyChars: "="), .in)
        XCTAssertEqual(ZoomKeyDirection(keyChars: "+"), .in, "⇧= arrives as +")
        XCTAssertEqual(ZoomKeyDirection(keyChars: "-"), .out)
        XCTAssertEqual(ZoomKeyDirection(keyChars: "0"), .actual)
    }

    /// Anything else must come back nil so the caller hands the event on untouched — the
    /// container sits over an editor whose own keys must keep working.
    func testEveryOtherKeyIsDeclined() {
        for key in ["1", "9", "a", "f", "_", "", " ", "\u{1b}"] {
            XCTAssertNil(ZoomKeyDirection(keyChars: key), "claimed \(key.debugDescription)")
        }
        XCTAssertNil(ZoomKeyDirection(keyChars: nil))
    }
}
