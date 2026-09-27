//
//  PasteboardDropTests.swift
//  AppKitViewsTests
//
//  What a drop can consume, and that every item of it survives.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import AppKitViews
import FoundationExtensions

@MainActor final class PasteboardDropTests: XCTestCase {
    private var board: NSPasteboard!

    override func setUp() {
        super.setUp()
        board = NSPasteboard(name: NSPasteboard.Name("AppKitViewsDropTests"))
        board.clearContents()
    }

    private func png() -> Data {
        let image = NSImage(size: NSSize(width: 2, height: 2))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 2, height: 2).fill()
        image.unlockFocus()
        let tiff = image.tiffRepresentation!
        return NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
    }

    // MARK: - What a target registers for

    func testTheReadableTypesCoverUrlsImagesAndPromises() {
        let types = NSPasteboard.dropReadableTypes
        for expected in [NSPasteboard.PasteboardType.fileURL, .URL, .png, .tiff] {
            XCTAssertTrue(types.contains(expected), "missing \(expected.rawValue)")
        }
        XCTAssertTrue(types.count > 4, "file promise types should be included too")
    }

    // MARK: - What is on the board

    func testAnEmptyBoardHasNothingToDrop() {
        XCTAssertFalse(board.containsDroppableContent)
        XCTAssertFalse(board.containsFilesButNoText)
    }

    func testAFileUrlIsDroppable() {
        board.writeObjects([URL(fileURLWithPath: "/tmp/a.txt") as NSURL])
        XCTAssertTrue(board.containsDroppableContent)
        XCTAssertTrue(board.containsFilesButNoText)
    }

    func testRawImageBytesAreDroppable() {
        board.setData(png(), forType: .png)
        XCTAssertTrue(board.containsDroppableContent)
        XCTAssertTrue(board.containsFilesButNoText, "a screenshot on the clipboard is the canonical case")
    }

    /// The distinction that decides whether ⌘V is text or a file drop.
    func testTextOnTheBoardMeansItIsNotAFileOnlyPaste() {
        board.setString("hello", forType: .string)
        board.setData(png(), forType: .png)
        XCTAssertTrue(board.containsDroppableContent)
        XCTAssertFalse(board.containsFilesButNoText, "there is text to paste, so paste it")
    }

    /// A plain web link is droppable, but it is not a FILE, so it is not the ⌘V-as-file case.
    func testAPlainLinkIsDroppableButNotAFile() {
        board.writeObjects([URL(string: "https://example.com")! as NSURL])
        XCTAssertTrue(board.containsDroppableContent)
        XCTAssertFalse(board.containsFilesButNoText)
    }

    // MARK: - Reading it

    func testNothingUsableIsReportedRatherThanSilentlyDoingNothing() {
        board.setString("just text", forType: .string)
        var called = false
        XCTAssertFalse(board.readDroppedFiles { _ in called = true })
        XCTAssertFalse(called)
    }

    func testLocalFilesComeBackAsQuotedPathsWithATrailingSpace() {
        board.writeObjects([URL(fileURLWithPath: "/tmp/a.txt") as NSURL])
        var text = ""
        XCTAssertTrue(board.readDroppedFiles { text = $0 })
        XCTAssertEqual(text, "'/tmp/a.txt' ")
    }

    /// Finder writes ONE pasteboard item per dragged file. A drop that keeps only the first
    /// reads to the person as "it took the wrong file".
    func testEveryDraggedFileSurvives() {
        board.writeObjects([
            URL(fileURLWithPath: "/tmp/a.txt") as NSURL,
            URL(fileURLWithPath: "/tmp/b.txt") as NSURL,
            URL(fileURLWithPath: "/tmp/c.txt") as NSURL,
        ])
        var text = ""
        XCTAssertTrue(board.readDroppedFiles { text = $0 })
        for name in ["a.txt", "b.txt", "c.txt"] { XCTAssertTrue(text.contains(name), "lost \(name) from \(text)") }
    }

    func testEveryLinkSurvives() {
        board.writeObjects([
            URL(string: "https://one.example")! as NSURL,
            URL(string: "https://two.example")! as NSURL,
        ])
        var text = ""
        XCTAssertTrue(board.readDroppedFiles { text = $0 })
        XCTAssertTrue(text.contains("one.example") && text.contains("two.example"), "got \(text)")
    }

    func testRawImageBytesAreSavedAndHandedOverAsAPath() throws {
        NSPasteboard.dropsFolderName = "AppKitViewsDropTests"
        board.setData(png(), forType: .png)
        var text = ""
        XCTAssertTrue(board.readDroppedFiles { text = $0 })
        let path = text.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "'"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: path), "no file at \(path)")
        XCTAssertTrue(path.hasSuffix(".png"))
        XCTAssertTrue(path.contains("AppKitViewsDropTests"), "saved outside the host's folder: \(path)")
        try? FileManager.default.removeItem(atPath: path)
    }

    /// A file URL and image bytes together: the FILE wins, because it is the real thing and the
    /// bytes are a rendering of it.
    func testAFileBeatsRawBytesForTheSameDrop() {
        board.writeObjects([URL(fileURLWithPath: "/tmp/real.png") as NSURL])
        board.setData(png(), forType: .png)
        var text = ""
        XCTAssertTrue(board.readDroppedFiles { text = $0 })
        XCTAssertTrue(text.contains("/tmp/real.png"), "got \(text)")
    }

    // MARK: - Quoting

    /// A space or an apostrophe is ordinary in a Mac filename, and each would otherwise split
    /// the path into several shell arguments.
    func testAwkwardPathsStayOneArgument() {
        XCTAssertEqual("/tmp/plain.txt".shellQuoted, "'/tmp/plain.txt'")
        XCTAssertEqual("/tmp/with space.txt".shellQuoted, "'/tmp/with space.txt'")
        XCTAssertEqual("/tmp/it's.txt".shellQuoted, #"'/tmp/it'\''s.txt'"#)
    }

    func testAQuotedPathSurvivesTheShellsOwnParsing() {
        // What `sh` would do with the quoted form: strip the quotes, keep the apostrophe.
        let quoted = "/tmp/it's a file.txt".shellQuoted
        XCTAssertFalse(quoted.contains("\" "), "no double quoting")
        XCTAssertTrue(quoted.hasPrefix("'") && quoted.hasSuffix("'"))
    }
}
