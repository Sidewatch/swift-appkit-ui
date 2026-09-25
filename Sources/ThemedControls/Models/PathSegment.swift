//
//  PathSegment.swift
//  ThemedControls
//
//  One crumb of a path bar: a title, and the file or folder it stands for when it stands for one.
//
//  Created by David Sherlock on 9/26/26.
//

import Foundation

/// One crumb of a path bar.
///
/// A crumb WITH a URL is a button whose menu lists that folder's contents. A crumb without one is
/// still a button if the host offers a menu for it, and plain text otherwise — which is how a bar
/// mixes a file's path with something that has no path at all, a symbol or "Untitled".
public struct PathSegment: Equatable, Sendable {
    public let title: String
    public let url: URL?
    /// Whether this crumb is a FOLDER, which decides whether its menu lists the folder itself or
    /// the file's siblings.
    ///
    /// The host says so; the bar does not ask the file system. Probing here would mean touching
    /// the disk on the main thread every time a menu opens, and would make the answer depend on
    /// whether the path happens to exist — a crumb for a file that has just been deleted, or one
    /// built for a path that is not on this disk at all, would silently change what its menu
    /// shows.
    public let isDirectory: Bool

    public init(title: String, url: URL?, isDirectory: Bool = false) {
        self.title = title
        self.url = url
        self.isDirectory = isDirectory
    }
}

/// One row of a folder crumb's menu, as the host lists it.
///
/// The HOST does the listing, not the bar. That keeps the bar free of file-system code and of any
/// opinion about hidden files, ignore rules or ordering — all of which belong to whatever is
/// already showing that same tree elsewhere in the app, and which would otherwise be decided
/// twice and drift.
public struct PathBarEntry: Equatable, Sendable {
    public let url: URL
    /// What the row reads. Usually the last path component.
    public let title: String
    /// A folder gets a submenu, filled only when it is opened.
    public let isFolder: Bool

    public init(url: URL, title: String, isFolder: Bool) {
        self.url = url
        self.title = title
        self.isFolder = isFolder
    }
}
