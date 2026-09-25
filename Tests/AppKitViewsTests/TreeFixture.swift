//
//  TreeFixture.swift
//  AppKitViewsTests
//
//  A synthetic outline of known shape, for the expansion tests.
//
//  Created by David Sherlock on 9/26/26.
//

import AppKit

/// One node of a tree whose shape the tests dictate exactly.
final class TreeNode {
    let name: String
    let children: [TreeNode]
    init(_ name: String, _ children: [TreeNode] = []) {
        self.name = name
        self.children = children
    }

    /// A tree with `breadth` nodes at each of `depth` levels.
    static func uniform(breadth: Int, depth: Int, prefix: String = "n") -> [TreeNode] {
        guard depth > 0 else { return [] }
        return (0..<breadth).map {
            TreeNode("\(prefix)\($0)", uniform(breadth: breadth, depth: depth - 1, prefix: "\(prefix)\($0)."))
        }
    }
}

/// Feeds an `NSOutlineView` a `TreeNode` forest. Counts the calls that build rows so a test can
/// tell a lazily-realised tree from one the view already knew about.
@MainActor final class TreeSource: NSObject, NSOutlineViewDataSource {
    let roots: [TreeNode]
    init(roots: [TreeNode]) { self.roots = roots }

    private func nodes(_ item: Any?) -> [TreeNode] { (item as? TreeNode)?.children ?? roots }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        nodes(item).count
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        nodes(item)[index]
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        !((item as? TreeNode)?.children.isEmpty ?? true)
    }
}

/// The outline, its data source, and the window holding it.
///
/// **The window is load-bearing, and it is the whole reason these tests are trustworthy.** An
/// `NSOutlineView` with no window takes a pathological path through its row bookkeeping:
/// measured 26 Sep 2026 on the same 22,764-row tree and the same code, expanding cost 0.696 s
/// and collapsing 4.846 s detached, against 0.030 s and 0.019 s hosted — a 250× difference in
/// the rig, none of it in the thing under test. A detached measurement would have condemned
/// correct code, and a bound loose enough to pass detached would never catch a real regression.
@MainActor func makeOutline(roots: [TreeNode]) -> (NSOutlineView, TreeSource, NSWindow) {
    let outline = NSOutlineView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
    let column = NSTableColumn(identifier: .init("name"))
    outline.addTableColumn(column)
    outline.outlineTableColumn = column
    let source = TreeSource(roots: roots)
    outline.dataSource = source
    outline.reloadData()

    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
                          styleMask: [.titled], backing: .buffered, defer: false)
    let scroll = NSScrollView(frame: window.contentView!.bounds)
    scroll.documentView = outline
    window.contentView?.addSubview(scroll)
    window.layoutIfNeeded()
    return (outline, source, window)
}

/// A data source that LOADS a node's children the first time it is asked for them, which is
/// what an on-demand tree actually does (Sidewatch's own file tree calls this
/// `loadChildrenIfNeeded`). It counts the loads, so a test can prove the walk really did reach
/// each level rather than reading a model that was there all along.
@MainActor final class LazyTreeSource: NSObject, NSOutlineViewDataSource {
    let roots: [TreeNode]
    private var realised: Set<ObjectIdentifier> = []
    init(roots: [TreeNode]) { self.roots = roots }

    /// How many distinct nodes have had their children loaded.
    var loadCount: Int { realised.count }

    private func nodes(_ item: Any?) -> [TreeNode] {
        guard let node = item as? TreeNode else { return roots }
        realised.insert(ObjectIdentifier(node))   // "loaded" on first ask, as an on-demand source is
        return node.children
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        nodes(item).count
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        nodes(item)[index]
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        !((item as? TreeNode)?.children.isEmpty ?? true)
    }
}

@MainActor func makeLazyOutline(roots: [TreeNode]) -> (NSOutlineView, LazyTreeSource, NSWindow) {
    let outline = NSOutlineView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
    let column = NSTableColumn(identifier: .init("name"))
    outline.addTableColumn(column)
    outline.outlineTableColumn = column
    let source = LazyTreeSource(roots: roots)
    outline.dataSource = source
    outline.reloadData()

    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
                          styleMask: [.titled], backing: .buffered, defer: false)
    let scroll = NSScrollView(frame: window.contentView!.bounds)
    scroll.documentView = outline
    window.contentView?.addSubview(scroll)
    window.layoutIfNeeded()
    return (outline, source, window)
}
