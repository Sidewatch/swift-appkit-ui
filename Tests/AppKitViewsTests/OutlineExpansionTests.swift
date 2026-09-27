//
//  OutlineExpansionTests.swift
//  AppKitViewsTests
//
//  Opening and closing an outline whole, and only as far as it stays readable.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import AppKitViews

@MainActor final class OutlineExpansionTests: XCTestCase {
    /// 3 × 3 × 3: 3 roots, 9 at level 1, 27 at level 2 = 39 rows fully open.
    private func smallTree() -> (NSOutlineView, TreeSource, NSWindow) {
        makeOutline(roots: TreeNode.uniform(breadth: 3, depth: 3))
    }

    func testExpandEveryNodeOpensEveryLevel() {
        let (outline, _, _) = smallTree()
        XCTAssertEqual(outline.numberOfRows, 3, "a fresh outline shows its roots only")
        outline.expandEveryNode()
        XCTAssertEqual(outline.numberOfRows, 3 + 9 + 27)
    }

    func testCollapseEveryNodeClosesEveryLevel() {
        let (outline, _, _) = smallTree()
        outline.expandEveryNode()
        outline.collapseEveryNode()
        XCTAssertEqual(outline.numberOfRows, 3)
    }

    /// One pass reaches every level, for an eager source and for one that loads a level when
    /// it is asked. This is the test that retired the repeat loop: it passes either way, and no
    /// source could be built that the loop rescued.
    func testOnePassReachesEveryLevelOfALazilyLoadedTree() {
        let (outline, _, window) = makeLazyOutline(roots: TreeNode.uniform(breadth: 3, depth: 3))
        outline.expandEveryNode()
        XCTAssertEqual(outline.numberOfRows, 3 + 9 + 27)
        withExtendedLifetime(window) {}
    }

    /// The first level opens however large, because a tree with closed roots says nothing.
    func testAutoExpandAlwaysOpensTheFirstLevel() {
        let (outline, _, _) = makeOutline(roots: TreeNode.uniform(breadth: 20, depth: 2))
        outline.autoExpand(rowLimit: 5)
        XCTAssertEqual(outline.numberOfRows, 20 + 400, "level 0 is exempt from the limit")
    }

    /// A level opens whole or not at all, so the depth is even.
    func testAutoExpandStopsAtTheLevelThatWouldOverflow() {
        // 3 roots, 9 at level 1, 27 at level 2. Opening level 1 costs 9 more rows (12 total);
        // opening level 2 would cost 27 more (39), so a limit of 20 must stop after level 1.
        let (outline, _, _) = smallTree()
        outline.autoExpand(rowLimit: 20)
        XCTAssertEqual(outline.numberOfRows, 12)
    }

    /// A tree that fits opens the whole way, which is the case a config file hits.
    func testAutoExpandOpensASmallTreeCompletely() {
        let (outline, _, _) = smallTree()
        outline.autoExpand(rowLimit: 400)
        XCTAssertEqual(outline.numberOfRows, 39)
    }

    /// A flat list has nothing to open and must not spin.
    func testAutoExpandOnAFlatListIsANoOp() {
        let (outline, _, _) = makeOutline(roots: (0..<5).map { TreeNode("leaf\($0)") })
        outline.autoExpand(rowLimit: 400)
        outline.expandEveryNode()
        XCTAssertEqual(outline.numberOfRows, 5)
    }

    /// NOTE: the COST of opening and closing a huge tree is pinned by Sidewatch's own
    /// `--selftest-config-views`, against a real tree with real cell views, not here. Hosted in
    /// a bare window the unbatched per-row walk measures as fast as the batched one, so any
    /// bound this rig could assert would pass against the quadratic version too — a check that
    /// cannot fail, implying coverage that is not there. The batching stays because it was
    /// measured where it matters: 0.39 s to open and 0.71 s to close a 22,000-row document
    /// per-row, against 0.21 s and 0.24 s batched.

}
