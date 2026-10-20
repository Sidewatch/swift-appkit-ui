//
//  SettingsWordListViewTests.swift
//  ThemedControlsTests
//
//  `SettingsWordListView`: loading a list canonicalizes it and stays silent; the rows show it.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// `SettingsWordListView.setWords` and the canonical form.
@MainActor
final class SettingsWordListViewTests: XCTestCase {
    func testSetWordsShowsTheCanonicalListWithoutCallingBack() {
        let list = SettingsWordListView()
        var changes = 0
        list.onChange = { _ in changes += 1 }
        list.setWords(["  node_modules ", "build", "", "Build", ".git"])
        XCTAssertEqual(list.words, [".git", "build", "node_modules"], "trimmed, blanks dropped, case-insensitive de-dupe, sorted")
        XCTAssertEqual(changes, 0, "loading is not a change")
        let table = list.listView.documentView as? NSTableView
        XCTAssertEqual(table.map { list.numberOfRows(in: $0) }, 3)
    }
}
