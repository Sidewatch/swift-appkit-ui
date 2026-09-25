//
//  PathBarViewTests.swift
//  ThemedControlsTests
//
//  Crumbs, their menus, and the keyboard walk — without ever popping a menu.
//
//  Created by David Sherlock on 9/26/26.
//

import XCTest
import AppKit
@testable import ThemedControls

@MainActor final class PathBarViewTests: XCTestCase {
    /// Builds a bar from (title, path, isDirectory) triples. Nothing touches the disk.
    private func bar(_ titles: [(String, String?, Bool)]) -> PathBarView {
        let b = PathBarView(frame: NSRect(x: 0, y: 0, width: 600, height: 24))
        b.setPath(segments: titles.map {
            PathSegment(title: $0.0, url: $0.1.map { URL(fileURLWithPath: $0) }, isDirectory: $0.2)
        })
        return b
    }

    /// A path whose last component is the file and the rest are folders.
    private func filePath(_ names: [String]) -> [(String, String?, Bool)] {
        var path = ""
        return names.enumerated().map { i, name in
            path += "/" + name
            return (name, path, i < names.count - 1)
        }
    }

    // MARK: - The strip

    func testACrumbIsBuiltForEverySegmentWithAChevronBetween() {
        let b = bar(filePath(["project", "src", "main.swift"]))
        XCTAssertEqual(b.crumbTitlesForTesting, ["project", "src", "main.swift"])
        let chevrons = b.crumbStack.arrangedSubviews.filter { $0.identifier == PathBarView.chevronIdentifier }
        XCTAssertEqual(chevrons.count, 2, "one between each pair, none at the ends")
    }

    func testASegmentWithNoUrlAndNoMenuProviderIsPlainText() {
        let b = bar([("Untitled", nil, false)])
        XCTAssertNil(b.crumbView(at: 0) as? NSButton)
        XCTAssertNotNil(b.crumbView(at: 0) as? NSTextField)
    }

    func testASegmentWithNoUrlBecomesAButtonWhenTheHostOffersAMenu() {
        let b = PathBarView(frame: .zero)
        b.titleSegmentMenuProvider = { _ in NSMenu() }
        b.setPath(segments: [PathSegment(title: "someFunction", url: nil)])
        XCTAssertNotNil(b.crumbView(at: 0) as? NSButton)
    }

    /// Rebuilding the strip would drop the focus under the keyboard, so an unchanged path is a
    /// no-op. The status bar refreshes on a timer, which is what makes this matter.
    func testSettingTheSamePathAgainDoesNotRebuild() {
        let b = bar(filePath(["a", "b"]))
        let first = b.crumbView(at: 0)
        b.setPath(segments: [PathSegment(title: "a", url: URL(fileURLWithPath: "/a"), isDirectory: true),
                             PathSegment(title: "b", url: URL(fileURLWithPath: "/a/b"))])
        XCTAssertTrue(b.crumbView(at: 0) === first, "the same views survived")
    }

    func testChangingThePathRebuilds() {
        let b = bar(filePath(["a", "b"]))
        b.setPath(segments: [PathSegment(title: "c", url: URL(fileURLWithPath: "/c"))])
        XCTAssertEqual(b.crumbTitlesForTesting, ["c"])
    }

    /// A long path must lose its ROOT before it loses the file name, which is the part you were
    /// reading. Each crumb resists the squeeze one point harder than the one before it.
    func testCrumbsGiveWayLeftFirst() {
        let b = bar(filePath(["one", "two", "three", "four"]))
        let priorities = (0..<4).compactMap {
            b.crumbView(at: $0)?.contentCompressionResistancePriority(for: .horizontal).rawValue
        }
        XCTAssertEqual(priorities.count, 4)
        XCTAssertEqual(priorities, priorities.sorted(), "later crumbs resist harder: \(priorities)")
    }

    /// A crumb genuinely named "›" must not be mistaken for a separator.
    func testACrumbNamedLikeAChevronIsStillACrumb() {
        let b = bar([("›", "/tmp/›", false)])
        XCTAssertNotNil(b.crumbView(at: 0), "the separator is marked, not recognised by its text")
    }

    // MARK: - Keyboard

    func testTheArrowsWalkTheCrumbsAndStopAtTheEnds() {
        let b = bar(filePath(["a", "b", "c"]))
        b.focus(at: 1)
        XCTAssertEqual(b.keyAction(for: 123), .move(0))   // ←
        XCTAssertEqual(b.keyAction(for: 124), .move(2))   // →
        b.focus(at: 0)
        XCTAssertEqual(b.keyAction(for: 123), .move(0), "no wrap at the start")
        b.focus(at: 2)
        XCTAssertEqual(b.keyAction(for: 124), .move(2), "no wrap at the end")
    }

    func testDownSpaceAndReturnAllOpenTheFocusedCrumb() {
        let b = bar(filePath(["a", "b"]))
        b.focus(at: 0)
        for key: UInt16 in [125, 49, 36] { XCTAssertEqual(b.keyAction(for: key), .open(0), "key \(key)") }
    }

    func testEscapeDismisses() {
        let b = bar(filePath(["a"]))
        XCTAssertEqual(b.keyAction(for: 53), .dismiss)
    }

    func testAnUnfocusedBarActsOnTheLastCrumb() {
        let b = bar(filePath(["a", "b", "c"]))
        XCTAssertNil(b.focusedCrumb)
        XCTAssertEqual(b.keyAction(for: 125), .open(2), "the file, which is what you meant")
        XCTAssertEqual(b.keyAction(for: 123), .move(1))
    }

    func testAnEmptyBarHandlesNothingAndTakesNoFocus() {
        let b = PathBarView(frame: .zero)
        XCTAssertEqual(b.keyAction(for: 123), .unhandled)
        XCTAssertEqual(b.keyAction(for: 53), .unhandled)
        XCTAssertFalse(b.acceptsFirstResponder)
    }

    func testOtherKeysAreNotClaimed() {
        let b = bar(filePath(["a"]))
        for key: UInt16 in [0, 12, 48, 51, 126] { XCTAssertEqual(b.keyAction(for: key), .unhandled, "key \(key)") }
    }

    func testDismissingTellsTheHostAndClearsTheHighlight() {
        let b = bar(filePath(["a", "b"]))
        var told = false
        b.onDismissFocus = { told = true }
        b.focus(at: 1)
        XCTAssertEqual(b.focusedCrumb, 1)
        b.dismissFocus()
        XCTAssertNil(b.focusedCrumb)
        XCTAssertTrue(told)
    }

    func testFocusingOutsideTheRangeIsIgnored() {
        let b = bar(filePath(["a", "b"]))
        b.focus(at: 9)
        XCTAssertNil(b.focusedCrumb)
    }

    // MARK: - Menus

    private func listing(_ b: PathBarView, _ entries: [PathBarEntry]) {
        b.childrenProvider = { _ in entries }
    }

    private func entry(_ name: String, in folder: String, isFolder: Bool = false) -> PathBarEntry {
        PathBarEntry(url: URL(fileURLWithPath: "\(folder)/\(name)"), title: name, isFolder: isFolder)
    }

    func testAFolderCrumbListsWhatTheHostGivesIt() {
        let b = bar([("tmp", "/tmp", true)])
        listing(b, [entry("a.txt", in: "/tmp"), entry("b.txt", in: "/tmp")])
        let menu = b.menu(forCrumbAt: 0)
        XCTAssertEqual(menu?.items.map(\.title), ["a.txt", "b.txt"])
    }

    /// A folder row OPENS rather than being picked. AppKit substitutes its own `submenuAction:`
    /// once an item has a submenu, so the check is that the folder does not carry the same action
    /// as a file — a click on the way to a file must not open the folder instead.
    func testAFolderRowOpensRatherThanBeingPicked() {
        let b = bar([("tmp", "/tmp", true)])
        listing(b, [entry("sub", in: "/tmp", isFolder: true), entry("a.txt", in: "/tmp")])
        let items = b.menu(forCrumbAt: 0)?.items ?? []
        XCTAssertNotNil(items[0].submenu)
        XCTAssertNil(items[1].submenu, "a file has no submenu")
        XCTAssertNotEqual(items[0].action, items[1].action, "the folder must not use the pick action")
    }

    /// A deep tree costs nothing until it is opened: a submenu is empty until AppKit asks.
    func testASubmenuIsFilledOnlyWhenItIsAboutToOpen() {
        let b = bar([("tmp", "/tmp", true)])
        var listedFolders: [String] = []
        b.childrenProvider = { folder in
            listedFolders.append(folder.lastPathComponent)
            return folder.lastPathComponent == "tmp" ? [self.entry("sub", in: "/tmp", isFolder: true)]
                                                     : [self.entry("deep.txt", in: "/tmp/sub")]
        }
        let sub = b.menu(forCrumbAt: 0)?.items.first?.submenu
        XCTAssertEqual(listedFolders, ["tmp"], "the subfolder is not listed yet")
        XCTAssertEqual(sub?.items.count, 0)
        b.menuNeedsUpdate(sub!)
        XCTAssertEqual(listedFolders, ["tmp", "sub"])
        XCTAssertEqual(sub?.items.map(\.title), ["deep.txt"])
    }

    func testAFolderCrumbTicksTheCrumbAfterIt() {
        let b = bar(filePath(["project", "src", "main.swift"]))
        listing(b, [entry("src", in: "/project", isFolder: true), entry("docs", in: "/project", isFolder: true)])
        let ticked = b.menu(forCrumbAt: 0)?.items.filter { $0.state == .on }.map(\.title)
        XCTAssertEqual(ticked, ["src"], "the path you are on through this folder")
    }

    func testAFileCrumbListsItsSiblingsAndTicksItself() {
        let b = bar(filePath(["project", "main.swift"]))
        listing(b, [entry("main.swift", in: "/project"), entry("other.swift", in: "/project")])
        let menu = b.menu(forCrumbAt: 1)
        XCTAssertEqual(menu?.items.map(\.title), ["main.swift", "other.swift"])
        XCTAssertEqual(menu?.items.filter { $0.state == .on }.map(\.title), ["main.swift"])
    }

    func testAnEmptyFolderSaysSoRatherThanDroppingNothing() {
        let b = bar([("tmp", "/tmp", true)])
        listing(b, [])
        let menu = b.menu(forCrumbAt: 0)
        XCTAssertEqual(menu?.items.map(\.title), ["Empty folder"])
        XCTAssertFalse(menu?.items.first?.isEnabled ?? true)
    }

    func testAHugeFolderIsCappedAndSaysHowManyMore() {
        let b = bar([("tmp", "/tmp", true)])
        listing(b, (0..<PathBarView.maxMenuEntries + 42).map { entry("f\($0).txt", in: "/tmp") })
        let items = b.menu(forCrumbAt: 0)?.items ?? []
        XCTAssertEqual(items.count, PathBarView.maxMenuEntries + 1)
        XCTAssertEqual(items.last?.title, "… 42 more")
        XCTAssertFalse(items.last?.isEnabled ?? true)
    }

    func testTheHostsOwnItemsGoAtTheTopAboveASeparator() {
        let b = bar([("shots", "/shots", true)])
        listing(b, [entry("a.png", in: "/shots")])
        b.leadingItemsProvider = { _ in [NSMenuItem(title: "Open as Gallery", action: nil, keyEquivalent: "")] }
        let items = b.menu(forCrumbAt: 0)?.items ?? []
        XCTAssertEqual(items.first?.title, "Open as Gallery")
        XCTAssertTrue(items[1].isSeparatorItem)
        XCTAssertEqual(items.last?.title, "a.png")
    }

    func testWithNoListingProviderAFolderReadsAsEmptyRatherThanCrashing() {
        let b = bar([("tmp", "/tmp", true)])
        XCTAssertEqual(b.menu(forCrumbAt: 0)?.items.map(\.title), ["Empty folder"])
    }

    func testAnOutOfRangeCrumbHasNoMenu() {
        let b = bar(filePath(["a"]))
        XCTAssertNil(b.menu(forCrumbAt: 5))
        XCTAssertNil(b.menu(forCrumbAt: -1))
    }

    /// A crumb with no URL asks by LEVEL among the url-less crumbs, not by its index in the bar.
    func testATitleCrumbIsAskedForByItsOwnLevel() {
        let b = PathBarView(frame: .zero)
        var asked: [Int] = []
        b.titleSegmentMenuProvider = { level in asked.append(level); return NSMenu() }
        b.setPath(segments: [PathSegment(title: "project", url: URL(fileURLWithPath: "/project")),
                             PathSegment(title: "main.swift", url: URL(fileURLWithPath: "/project/main.swift")),
                             PathSegment(title: "MyType", url: nil),
                             PathSegment(title: "method", url: nil)])
        _ = b.menu(forCrumbAt: 2)
        _ = b.menu(forCrumbAt: 3)
        XCTAssertEqual(asked, [0, 1])
    }

    func testPickingAFileReportsItAndGivesTheKeyboardBack() {
        let b = bar([("tmp", "/tmp", true)])
        listing(b, [entry("a.txt", in: "/tmp")])
        var picked: URL?
        var dismissed = false
        b.onPick = { picked = $0 }
        b.onDismissFocus = { dismissed = true }
        b.focus(at: 0)
        let item = b.menu(forCrumbAt: 0)!.items[0]
        _ = item.target?.perform(item.action!, with: item)
        XCTAssertEqual(picked?.lastPathComponent, "a.txt")
        XCTAssertTrue(dismissed)
    }

    func testTheHostsIconIsUsedWhenItGivesOne() {
        let b = bar([("tmp", "/tmp", true)])
        listing(b, [entry("a.txt", in: "/tmp")])
        b.iconProvider = { _ in NSImage(systemSymbolName: "star", accessibilityDescription: nil) }
        XCTAssertNotNil(b.menu(forCrumbAt: 0)?.items.first?.image)
    }
}
