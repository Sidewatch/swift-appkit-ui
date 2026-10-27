//
//  LargeTextPosition.swift
//  AppKitViews
//
//  A place in a large text: a line and a column in it.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// A place in a large text: a 0-based line and a column in it. In a line the view decodes whole the column is a
/// UTF-16 offset into its text; in a line too long to decode (``LargeTextView/wholeLineLimit``) it is a byte
/// offset into the line.
public struct LargeTextPosition: Comparable, Hashable, Sendable {
    /// The 0-based line.
    public var line: Int
    /// The column: a UTF-16 offset into a line decoded whole, a byte offset into a longer one.
    public var column: Int

    /// A position from its line and column.
    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }

    public static func < (a: LargeTextPosition, b: LargeTextPosition) -> Bool {
        a.line < b.line || (a.line == b.line && a.column < b.column)
    }
}
