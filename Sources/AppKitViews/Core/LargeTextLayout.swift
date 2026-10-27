//
//  LargeTextLayout.swift
//  AppKitViews
//
//  The arithmetic of a large text view: where lines sit, how far it scrolls, what its scrollers show.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import CoreGraphics
import Foundation

/// The arithmetic of a ``LargeTextView``, apart from the view: lines of one height from a fractional top line, a
/// gutter wide enough for the last line's number, and scrolling bounded so the last line can rest at the bottom.
/// Positions are in lines, not points: a hundred million lines are 1.6 billion points tall, past what a layer
/// places precisely.
public struct LargeTextLayout: Equatable, Sendable {
    /// The text area's size: the view less its gutter and scrollers.
    public var viewport: CGSize
    public var lineHeight: CGFloat
    public var characterWidth: CGFloat
    public var lineCount: Int
    /// The longest line in bytes, which is its width in characters for the ASCII a long line nearly always is.
    public var longestLine: Int

    /// Room left and right of the gutter's numbers, and before the text.
    public static let padding: CGFloat = 8

    public init(viewport: CGSize, lineHeight: CGFloat, characterWidth: CGFloat, lineCount: Int, longestLine: Int) {
        self.viewport = viewport
        self.lineHeight = lineHeight
        self.characterWidth = characterWidth
        self.lineCount = lineCount
        self.longestLine = longestLine
    }

    /// How many lines the viewport holds, the part of one counted as a fraction.
    public var linesPerPage: Double { lineHeight > 0 ? Double(viewport.height / lineHeight) : 0 }

    /// The furthest the top line can go: the last line at the bottom edge, or 0 when everything fits.
    public var maxTopLine: Double { max(0, Double(lineCount) - linesPerPage) }

    /// The furthest the text can scroll left: the longest line's end at the right edge.
    public var maxLeftX: CGFloat { max(0, CGFloat(longestLine) * characterWidth + Self.padding * 2 - viewport.width) }

    /// `top` kept between the first line and ``maxTopLine``.
    public func clampedTop(_ top: Double) -> Double { min(max(0, top), maxTopLine) }

    /// `left` kept between the left edge and ``maxLeftX``.
    public func clampedLeft(_ left: CGFloat) -> CGFloat { min(max(0, left), maxLeftX) }

    /// The lines on screen for a top line: from the one at the top edge to the one cut by the bottom edge.
    public func visibleLines(top: Double) -> Range<Int> {
        let first = max(0, Int(top.rounded(.down)))
        let last = min(lineCount, Int((top + linesPerPage).rounded(.up)))
        return first..<max(first, last)
    }

    /// Where `line`'s top edge is, from the viewport's top.
    public func y(ofLine line: Int, top: Double) -> CGFloat { CGFloat(Double(line) - top) * lineHeight }

    /// The line under `y` (from the viewport's top), which may be past the last line.
    public func line(atY y: CGFloat, top: Double) -> Int { Int((top + Double(y / lineHeight)).rounded(.down)) }

    /// The top line that puts `line` in the middle of the viewport, clamped.
    public func topCentring(_ line: Int) -> Double { clampedTop(Double(line) - linesPerPage / 2 + 0.5) }

    /// The top line that brings `line` fully into view, moving as little as possible.
    public func topRevealing(_ line: Int, from top: Double) -> Double {
        if Double(line) < top { return clampedTop(Double(line)) }
        if Double(line + 1) > top + linesPerPage { return clampedTop(Double(line + 1) - linesPerPage) }
        return top
    }

    /// A vertical scroller's knob size and position for a top line.
    public func scroller(top: Double) -> (proportion: CGFloat, value: Double) {
        guard lineCount > 0, maxTopLine > 0 else { return (1, 0) }
        return (CGFloat(min(1, linesPerPage / Double(lineCount))), top / maxTopLine)
    }

    /// The top line a vertical scroller's value stands for.
    public func top(forScrollerValue value: Double) -> Double { clampedTop(min(max(0, value), 1) * maxTopLine) }

    /// The gutter's width: the widest line number and the padding either side of it.
    public static func gutterWidth(lineCount: Int, characterWidth: CGFloat) -> CGFloat {
        CGFloat(String(max(1, lineCount)).count) * characterWidth + padding * 2
    }
}
