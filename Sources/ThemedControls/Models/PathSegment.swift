//
//  PathSegment.swift
//  ThemedControls
//
//  One crumb of a path bar: a title, and the file or folder it stands for when it stands for one.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// One crumb of a path bar.
///
/// A crumb WITH a URL is a button whose menu lists that folder's contents. A crumb without one is
/// still a button if the host offers a menu for it, and plain text otherwise — which is how a bar
/// mixes a file's path with something that has no path at all, a symbol or "Untitled".
public struct PathSegment: Equatable, Sendable {
    /// What the crumb reads.
    public let title: String
    /// The file or folder the crumb stands for; nil for a title-only crumb.
    public let url: URL?
    /// Whether this crumb is a FOLDER, which decides whether its menu lists the folder itself or
    /// the file's siblings.
    ///
    /// The host says so; the bar must not probe the disk — that is main-thread I/O on every menu,
    /// and a just-deleted path would silently change what its menu shows.
    public let isDirectory: Bool

    /// Creates a crumb.
    public init(title: String, url: URL?, isDirectory: Bool = false) {
        self.title = title
        self.url = url
        self.isDirectory = isDirectory
    }
}

/// One row of a folder crumb's menu, as the host lists it — the bar holds no opinion on hidden
/// files, ignore rules or ordering.
public struct PathBarEntry: Equatable, Sendable {
    /// The file or folder the row picks.
    public let url: URL
    /// What the row reads. Usually the last path component.
    public let title: String
    /// A folder gets a submenu, filled only when it is opened.
    public let isFolder: Bool

    /// Creates a row.
    public init(url: URL, title: String, isFolder: Bool) {
        self.url = url
        self.title = title
        self.isFolder = isFolder
    }
}
