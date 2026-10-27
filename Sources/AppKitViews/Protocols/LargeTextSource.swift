//
//  LargeTextSource.swift
//  AppKitViews
//
//  What a large text view reads: lines located on demand, bytes decoded on demand.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// What a ``LargeTextView`` reads: a text of any size whose lines are located and decoded only when asked for, so
/// the view never holds more than the lines on screen. Offsets are in the source's own bytes; a line's range
/// leaves out its line break.
public protocol LargeTextSource: AnyObject {
    /// The lines that can be asked for now; a source still scanning reports more later.
    var lineCount: Int { get }
    /// The longest line found so far, in bytes: the horizontal extent.
    var longestLineBytes: Int { get }
    /// The bytes of 0-based `line`, without its break; nil for a line not yet found.
    func byteRange(ofLine line: Int) -> Range<Int>?
    /// The text of the bytes in `range`.
    func text(in range: Range<Int>) -> String
    /// `offset`, or the start of the character it falls inside.
    func characterStart(atOrBefore offset: Int) -> Int
    /// The 0-based line holding byte `offset`.
    func line(containingByte offset: Int) -> Int
}
