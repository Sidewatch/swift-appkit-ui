//
//  TextViewScrollHostingTests.swift
//  AppKitViewsTests
//
//  `configureForVerticalScrolling`: a text view in a scroll view grows to its text and wraps
//  at the scroll view's width.
//
//  Created by David Sherlock on 10/20/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import AppKitViews

/// `configureForVerticalScrolling`, measured in a window.
@MainActor
final class TextViewScrollHostingTests: XCTestCase {
    func testTheTextViewGrowsTallerThanTheClipAndWrapsAtItsWidth() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200), styleMask: [.titled], backing: .buffered, defer: false)
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        scroll.hasVerticalScroller = true
        // The case the helper is for: a view built over its own container, whose maximum size
        // defaults to its frame and whose container does not track it.
        let storage = NSTextStorage()
        let layout = NSLayoutManager()
        let container = NSTextContainer(size: NSSize(width: 100, height: 100))
        layout.addTextContainer(container)
        storage.addLayoutManager(layout)
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: scroll.contentSize.width, height: 0), textContainer: container)
        textView.configureForVerticalScrolling()
        scroll.documentView = textView
        window.contentView = scroll
        textView.string = (1...200).map { "line \($0) with enough words to wrap at three hundred points wide" }.joined(separator: "\n")
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        textView.sizeToFit()
        XCTAssertGreaterThan(textView.frame.height, scroll.contentSize.height * 10, "it grows to its text, so the scroll view scrolls")
        XCTAssertLessThanOrEqual(textView.frame.width, scroll.contentSize.width + 0.5, "it wraps at the scroll view's width")
        XCTAssertTrue(textView.textContainer?.widthTracksTextView == true)
        window.orderOut(nil)
    }
}
