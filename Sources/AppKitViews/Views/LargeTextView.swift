//
//  LargeTextView.swift
//  AppKitViews
//
//  A read-only view of a text of any size: only the lines on screen are read and drawn.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A read-only view of a text of any size: only the lines on screen are read from the ``LargeTextSource`` and
/// drawn, with Core Text, in one monospaced font, so a 10 GB log scrolls like a short one and the view holds no
/// text of its own. It scrolls by line rather than by point (``LargeTextLayout``), with its own scrollers, and a
/// line too long to decode whole is read only as far as the screen shows it. A gutter numbers the lines; the mouse
/// and the keyboard select, ⌘C copies, and a search marks what it finds through ``matchFinder``, asked for the lines
/// on screen as they draw, so it never has to hold every match, and moves to one with ``showMatch(_:)``.
///
/// The source may still be finding its lines: call ``sourceDidGrow()`` as it does, and when the text itself grows
/// (a log being written), and a view resting at the last line follows it down.
public final class LargeTextView: NSView {
    /// A line longer than this many bytes is never decoded whole: only the stretch on screen is read.
    public static let wholeLineLimit = 16 << 10

    /// The most a copy takes, in bytes; a larger selection is refused through ``onCopyRefused``.
    public static let copyLimit = 64 << 20

    /// What the view shows. Setting it starts at the top with nothing selected.
    public var source: LargeTextSource? {
        didSet {
            topLine = 0
            leftX = 0
            anchor = nil
            head = nil
            matchFinder = nil
            currentMatch = nil
            refresh()
        }
    }

    /// The font and colours.
    public var style: LargeTextStyle = .system {
        didSet {
            measure()
            refresh()
        }
    }

    /// Called when the selection changes, with its two ends in order, or nil when nothing is selected.
    public var onSelectionChange: ((ClosedRange<LargeTextPosition>?) -> Void)?

    /// Called with the selection's size in bytes when ⌘C refuses one past ``copyLimit``.
    public var onCopyRefused: ((Int) -> Void)?

    /// What a right-click shows; nil shows nothing.
    public var contextMenu: NSMenu?

    /// The line at the top edge, with the part of it scrolled past as a fraction.
    public private(set) var topLine: Double = 0

    /// How far the text is scrolled left, in points.
    public private(set) var leftX: CGFloat = 0

    /// The selection's fixed end and its moving end.
    var anchor: LargeTextPosition?
    var head: LargeTextPosition?

    /// The matches of a search in a stretch of the source's bytes — a line on screen, or the part of a long one that
    /// is — as byte ranges into the source, in order; asked for as the screen draws. Nil marks nothing.
    public var matchFinder: ((Range<Int>) -> [Range<Int>])? { didSet { needsDisplay = true } }

    /// The match the search last moved to, drawn in its own colour.
    public internal(set) var currentMatch: Range<Int>?

    let verticalScroller = NSScroller()
    let horizontalScroller = NSScroller()

    /// The line count the view last laid itself out for.
    var laidOutLineCount = 0

    /// The font's line height, its character width and the baseline's distance from a line's top.
    var lineHeight: CGFloat = 16
    var characterWidth: CGFloat = 7
    var ascent: CGFloat = 12

    public override var isFlipped: Bool { true }
    public override var acceptsFirstResponder: Bool { true }
    public override var isOpaque: Bool { true }

    public override init(frame: NSRect) {
        super.init(frame: frame)
        setUp()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        for scroller in [verticalScroller, horizontalScroller] {
            scroller.scrollerStyle = .legacy
            scroller.isEnabled = true
            scroller.target = self
            addSubview(scroller)
        }
        verticalScroller.action = #selector(verticalScrollerMoved(_:))
        horizontalScroller.action = #selector(horizontalScrollerMoved(_:))
        measure()
    }

    // MARK: - Geometry

    /// The text area's arithmetic now.
    public var layoutModel: LargeTextLayout {
        LargeTextLayout(
            viewport: textArea.size, lineHeight: lineHeight, characterWidth: characterWidth, lineCount: source?.lineCount ?? 0,
            longestLine: source?.longestLineBytes ?? 0)
    }

    /// The gutter's width, for the number of the last line.
    var gutterWidth: CGFloat { LargeTextLayout.gutterWidth(lineCount: source?.lineCount ?? 1, characterWidth: characterWidth) }

    /// A scroller's thickness.
    var scrollerWidth: CGFloat { NSScroller.scrollerWidth(for: .regular, scrollerStyle: .legacy) }

    /// Where the text is drawn: the bounds less the gutter and the scrollers.
    var textArea: NSRect {
        NSRect(
            x: gutterWidth, y: 0, width: max(0, bounds.width - gutterWidth - scrollerWidth), height: max(0, bounds.height - scrollerWidth))
    }

    /// Reads the font's metrics.
    private func measure() {
        let font = style.font
        ascent = ceil(font.ascender)
        lineHeight = ceil(font.ascender - font.descender + font.leading)
        characterWidth = ("0" as NSString).size(withAttributes: [.font: font]).width
    }

    public override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        topLine = layoutModel.clampedTop(topLine)
        leftX = layoutModel.clampedLeft(leftX)
        placeScrollers()
    }

    private func placeScrollers() {
        verticalScroller.frame = NSRect(
            x: bounds.width - scrollerWidth, y: 0, width: scrollerWidth, height: max(0, bounds.height - scrollerWidth))
        horizontalScroller.frame = NSRect(
            x: 0, y: bounds.height - scrollerWidth, width: max(0, bounds.width - scrollerWidth), height: scrollerWidth)
        updateScrollers()
    }

    /// The scrollers' knobs from the scroll position.
    func updateScrollers() {
        let model = layoutModel
        let vertical = model.scroller(top: topLine)
        verticalScroller.knobProportion = vertical.proportion
        verticalScroller.doubleValue = vertical.value
        verticalScroller.isEnabled = model.maxTopLine > 0
        let maxLeft = model.maxLeftX
        horizontalScroller.knobProportion = maxLeft > 0 ? model.viewport.width / (model.viewport.width + maxLeft) : 1
        horizontalScroller.doubleValue = maxLeft > 0 ? Double(leftX / maxLeft) : 0
        horizontalScroller.isEnabled = maxLeft > 0
    }

    /// Redraws everything after the source, the style or the position changed.
    func refresh() {
        laidOutLineCount = source?.lineCount ?? 0
        topLine = layoutModel.clampedTop(topLine)
        leftX = layoutModel.clampedLeft(leftX)
        placeScrollers()
        needsDisplay = true
    }

    /// Takes in more lines from the source (a scan going on, a log growing). A view resting at the last line stays
    /// there, so a growing log is followed.
    public func sourceDidGrow() {
        var before = layoutModel
        before.lineCount = laidOutLineCount  // the source has grown already: where the bottom WAS
        let following = before.maxTopLine > 0 && topLine >= before.maxTopLine - 0.5
        if following { topLine = layoutModel.maxTopLine }
        refresh()
    }

    // MARK: - Scrolling

    /// Puts line `top` (fractional) at the top edge, as far as the text allows.
    public func scroll(toTop top: Double) {
        let clamped = layoutModel.clampedTop(top)
        guard clamped != topLine else { return }
        topLine = clamped
        updateScrollers()
        needsDisplay = true
    }

    /// Scrolls the text `left` points from its left edge, as far as it allows.
    public func scroll(toLeft left: CGFloat) {
        let clamped = layoutModel.clampedLeft(left)
        guard clamped != leftX else { return }
        leftX = clamped
        updateScrollers()
        needsDisplay = true
    }

    /// Brings 0-based `line` to the middle of the view.
    public func scrollToLine(_ line: Int) { scroll(toTop: layoutModel.topCentring(line)) }

    public override func scrollWheel(with event: NSEvent) {
        let scale: CGFloat = event.hasPreciseScrollingDeltas ? 1 : lineHeight
        if event.scrollingDeltaY != 0 { scroll(toTop: topLine - Double(event.scrollingDeltaY * scale / lineHeight)) }
        if event.scrollingDeltaX != 0 { scroll(toLeft: leftX - event.scrollingDeltaX * scale) }
    }

    @objc private func verticalScrollerMoved(_ sender: NSScroller) {
        let model = layoutModel
        switch sender.hitPart {
        case .decrementPage: scroll(toTop: topLine - max(1, model.linesPerPage - 1))
        case .incrementPage: scroll(toTop: topLine + max(1, model.linesPerPage - 1))
        case .decrementLine: scroll(toTop: topLine - 1)
        case .incrementLine: scroll(toTop: topLine + 1)
        default: scroll(toTop: model.top(forScrollerValue: sender.doubleValue))
        }
    }

    @objc private func horizontalScrollerMoved(_ sender: NSScroller) {
        let model = layoutModel
        switch sender.hitPart {
        case .decrementPage: scroll(toLeft: leftX - model.viewport.width)
        case .incrementPage: scroll(toLeft: leftX + model.viewport.width)
        default: scroll(toLeft: CGFloat(sender.doubleValue) * model.maxLeftX)
        }
    }

    // MARK: - Keys

    public override func keyDown(with event: NSEvent) { interpretKeyEvents([event]) }

    public override func moveUp(_ sender: Any?) { scroll(toTop: topLine - 1) }
    public override func moveDown(_ sender: Any?) { scroll(toTop: topLine + 1) }
    public override func moveLeft(_ sender: Any?) { scroll(toLeft: leftX - characterWidth * 4) }
    public override func moveRight(_ sender: Any?) { scroll(toLeft: leftX + characterWidth * 4) }
    public override func pageUp(_ sender: Any?) { scroll(toTop: topLine - max(1, layoutModel.linesPerPage - 1)) }
    public override func pageDown(_ sender: Any?) { scroll(toTop: topLine + max(1, layoutModel.linesPerPage - 1)) }
    public override func scrollPageUp(_ sender: Any?) { pageUp(sender) }
    public override func scrollPageDown(_ sender: Any?) { pageDown(sender) }
    public override func moveToBeginningOfDocument(_ sender: Any?) { scroll(toTop: 0) }
    public override func moveToEndOfDocument(_ sender: Any?) { scroll(toTop: layoutModel.maxTopLine) }
    public override func scrollToBeginningOfDocument(_ sender: Any?) { scroll(toTop: 0) }
    public override func scrollToEndOfDocument(_ sender: Any?) { scroll(toTop: layoutModel.maxTopLine) }
    public override func moveToBeginningOfLine(_ sender: Any?) { scroll(toLeft: 0) }
    public override func moveToEndOfLine(_ sender: Any?) { scroll(toLeft: layoutModel.maxLeftX) }

    /// Space pages down and Shift-Space up, as in a pager; nothing else is typed into a read-only view.
    public override func insertText(_ insertString: Any) {
        guard (insertString as? String) == " " else { return NSSound.beep() }
        if NSApp.currentEvent?.modifierFlags.contains(.shift) == true { pageUp(nil) } else { pageDown(nil) }
    }

    public override func doCommand(by selector: Selector) {
        if responds(to: selector) { perform(selector, with: nil) } else { super.doCommand(by: selector) }
    }

    /// The host's menu for a right-click (its titles are the host's to word), or an empty one, so a right-click
    /// never reaches whatever lies beneath.
    public override func menu(for event: NSEvent) -> NSMenu? { contextMenu ?? NSMenu() }
}
