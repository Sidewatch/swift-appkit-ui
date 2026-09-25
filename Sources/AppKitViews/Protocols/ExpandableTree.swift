//
//  ExpandableTree.swift
//  AppKitViews
//
//  A view whose content is a tree that can be opened or closed whole.
//
//  Created by David Sherlock on 9/26/26.
//

import AppKit

/// A view whose content is a tree, so a host can offer Expand All and Collapse All against
/// whichever tree is in front without knowing what any of them are showing.
@MainActor public protocol ExpandableTree: NSView {
    /// Opens every node, however deep.
    func expandAllNodes()
    /// Closes every node.
    func collapseAllNodes()
}
