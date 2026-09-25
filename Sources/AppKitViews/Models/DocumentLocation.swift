//
//  DocumentLocation.swift
//  AppKitViews
//
//  A place in a document: a file and a range within it.
//
//  Created by David Sherlock on 9/26/26.
//

import Foundation

/// A place in a document — a file and a range within it — captured so it can be returned to.
///
/// Captured at jump time and never revalidated. A file edited or deleted since is handled when
/// the location is USED, by clamping or skipping, rather than by trying to keep a stack of
/// positions live against a document that keeps moving underneath it.
public struct DocumentLocation: Equatable, Sendable {
    /// The file the position is in.
    public let url: URL
    /// The range within it, in UTF-16 units.
    public let range: NSRange

    public init(url: URL, range: NSRange) {
        self.url = url
        self.range = range
    }

    public static func == (a: DocumentLocation, b: DocumentLocation) -> Bool {
        a.url == b.url && NSEqualRanges(a.range, b.range)
    }
}
