//
//  PaneTreeTests.swift
//  PaneLayoutTests
//
//  The four structural rules: insert on the same axis, wrap across it, reset flexes, collapse.
//
//  Created by David Sherlock on 9/26/26.
//

import XCTest
import AppKit
@testable import PaneLayout

/// A leaf that can say whether it is "empty", so the invariant check has something to ask.
final class TestLeaf: NSView {
    var contents = 1
    let name: String
    init(_ name: String = "leaf") {
        self.name = name
        super.init(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
    }
    required init?(coder: NSCoder) { fatalError() }
}

@MainActor final class PaneTreeTests: XCTestCase {
    private var made = 0

    private func makeTree() -> PaneTree<TestLeaf> {
        made = 0
        let tree = PaneTree<TestLeaf> { [self] in made += 1; return TestLeaf("leaf\(made)") }
        tree.isLeafEmpty = { $0.contents == 0 }
        tree.container.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        return tree
    }

    private func axis(_ tree: PaneTree<TestLeaf>) -> PaneAxisView? { tree.root as? PaneAxisView }

    // MARK: - Shape

    func testAFreshTreeIsOneLeaf() {
        let tree = makeTree()
        let root = tree.createRootLeaf()
        XCTAssertTrue(tree.root === root)
        XCTAssertEqual(tree.panes.count, 1)
        XCTAssertTrue(tree.lastFocused === root)
    }

    func testTheFirstSplitPutsAnAxisAtTheRoot() {
        let tree = makeTree()
        let first = tree.createRootLeaf()
        let second = tree.split(first, .right)
        XCTAssertNotNil(second)
        XCTAssertEqual(axis(tree)?.orientation, .horizontal)
        XCTAssertEqual(axis(tree)?.members.count, 2)
        XCTAssertTrue(axis(tree)?.members.first === first, "right puts the NEW pane after")
    }

    func testSplittingLeftOrUpPutsTheNewPaneFirst() {
        for direction in [PaneSplitDirection.left, .up] {
            let tree = makeTree()
            let first = tree.createRootLeaf()
            let second = tree.split(first, direction)
            XCTAssertTrue(axis(tree)?.members.first === second, "\(direction) puts the new pane first")
        }
    }

    /// Same axis INSERTS, so the tree stays flat instead of growing a spine of pairs.
    func testASameAxisSplitInsertsRatherThanNesting() {
        let tree = makeTree()
        let a = tree.createRootLeaf()
        let b = tree.split(a, .right)!
        _ = tree.split(b, .right)
        XCTAssertEqual(axis(tree)?.members.count, 3, "three members on ONE axis")
        XCTAssertNil(axis(tree)?.members.compactMap { $0 as? PaneAxisView }.first, "no nested axis")
        XCTAssertEqual(tree.panes.count, 3)
    }

    /// Crossing the axis WRAPS in place, so the parent's other members and flexes are untouched.
    func testACrossAxisSplitWrapsInPlaceAndLeavesTheParentAlone() {
        let tree = makeTree()
        let a = tree.createRootLeaf()
        let b = tree.split(a, .right)!
        _ = tree.split(b, .right)                        // three across
        let parent = axis(tree)!
        // UNEVEN on purpose: with equal flexes a remove-and-reinsert would look identical, and
        // the whole point of replacing in place is that the wrapper inherits the slot's share.
        parent.setFlexes([1.5, 1.0, 0.5])
        _ = tree.split(b, .down)                         // cross the axis on the middle member
        XCTAssertEqual(parent.members.count, 3, "the parent keeps its member count")
        XCTAssertEqual(parent.flexes, [1.5, 1.0, 0.5], "the wrapper inherits the slot's fraction")
        let wrapper = parent.members[1] as? PaneAxisView
        XCTAssertEqual(wrapper?.orientation, .vertical)
        XCTAssertEqual(wrapper?.members.count, 2)
        XCTAssertEqual(tree.panes.count, 4)
    }

    // MARK: - Flexes

    func testEveryMembershipChangeResetsThatAxisToEqualShares() {
        let tree = makeTree()
        let a = tree.createRootLeaf()
        let b = tree.split(a, .right)!
        axis(tree)!.setFlexes([1.6, 0.4])
        _ = tree.split(b, .right)
        XCTAssertEqual(axis(tree)!.flexes, [1, 1, 1])
    }

    func testFlexesAlwaysSumToTheMemberCount() {
        let tree = makeTree()
        let a = tree.createRootLeaf()
        let b = tree.split(a, .right)!
        _ = tree.split(b, .down)
        for a in [axis(tree)!] + axis(tree)!.members.compactMap({ $0 as? PaneAxisView }) {
            XCTAssertEqual(a.flexes.count, a.members.count)
            XCTAssertEqual(a.flexes.reduce(0, +), CGFloat(a.members.count), accuracy: 0.01)
        }
    }

    func testARejectedFlexVectorIsIgnoredRatherThanCorrupting() {
        let tree = makeTree()
        let a = tree.createRootLeaf()
        _ = tree.split(a, .right)
        axis(tree)!.setFlexes([1, 1, 1])                 // wrong count
        XCTAssertEqual(axis(tree)!.flexes, [1, 1])
    }

    // MARK: - Collapse

    func testAnAxisLeftWithOneMemberPopsItToTheRoot() {
        let tree = makeTree()
        let a = tree.createRootLeaf()
        let b = tree.split(a, .right)!
        tree.remove(b)
        XCTAssertTrue(tree.root === a, "the survivor becomes the root, not a one-member axis")
        XCTAssertEqual(tree.panes.count, 1)
    }

    /// A popped axis matching its parent's orientation is spliced FLAT, so one run of dividers
    /// keeps ruling it rather than two sets meeting in the middle.
    func testAPoppedAxisOfTheSameOrientationIsSplicedFlat() {
        let tree = makeTree()
        let a = tree.createRootLeaf()
        let b = tree.split(a, .right)!                   // [a, b] horizontal
        let c = tree.split(b, .down)!                    // b wrapped vertically: [a, V[b, c]]
        let d = tree.split(c, .right)!                   // V[b, H[c, d]]
        _ = d
        tree.remove(b)                                   // V has one member, H[c, d] — same axis as root
        XCTAssertEqual(axis(tree)?.orientation, .horizontal)
        XCTAssertEqual(axis(tree)?.members.count, 3, "a, c and d on one horizontal run")
        XCTAssertTrue(axis(tree)?.members.allSatisfy { $0 is TestLeaf } ?? false, "no axis left inside")
    }

    func testRemovingTheLastLeafEmptiesTheTree() {
        let tree = makeTree()
        let a = tree.createRootLeaf()
        tree.remove(a)
        XCTAssertNil(tree.root)
        XCTAssertNil(tree.lastFocused)
        XCTAssertTrue(tree.panes.isEmpty)
    }

    // MARK: - Focus

    /// Removing an UNFOCUSED leaf must not move the focus target, or a background pane finishing
    /// on its own would steal where your next split lands.
    func testRemovingAnUnfocusedLeafLeavesTheFocusTargetAlone() {
        let tree = makeTree()
        let a = tree.createRootLeaf()
        let b = tree.split(a, .right)!
        let c = tree.split(b, .right)!
        tree.lastFocused = a
        tree.remove(c)
        XCTAssertTrue(tree.lastFocused === a)
    }

    func testRemovingTheFocusedLeafFallsBackToItsNearestSibling() {
        let tree = makeTree()
        let a = tree.createRootLeaf()
        let b = tree.split(a, .right)!
        let c = tree.split(b, .right)!
        tree.lastFocused = c
        tree.remove(c)
        XCTAssertTrue(tree.lastFocused === b, "the previous member, not the first pane")
    }

    func testFocusedPaneFallsBackWhenNothingHoldsFirstResponder() {
        let tree = makeTree()
        let a = tree.createRootLeaf()
        let b = tree.split(a, .right)!
        tree.lastFocused = b
        XCTAssertTrue(tree.focusedPane(in: nil) === b)
        tree.lastFocused = nil
        XCTAssertTrue(tree.focusedPane(in: nil) === a, "else the first pane")
    }

    func testSplittingALeafNotInTheTreeDoesNothing() {
        let tree = makeTree()
        _ = tree.createRootLeaf()
        XCTAssertNil(tree.split(TestLeaf("stranger"), .right))
        XCTAssertEqual(tree.panes.count, 1)
    }

    // MARK: - The corner

    func testTheCornerIsHighestThenRightmost() {
        XCTAssertEqual(PaneTree<TestLeaf>.cornerIndex(of: []), nil)
        // Non-flipped: a bigger maxY is higher on screen.
        let grid = [NSRect(x: 0, y: 0, width: 10, height: 10),      // bottom-left
                    NSRect(x: 20, y: 0, width: 10, height: 10),     // bottom-right
                    NSRect(x: 0, y: 20, width: 10, height: 10),     // top-left
                    NSRect(x: 20, y: 20, width: 10, height: 10)]    // top-right
        XCTAssertEqual(PaneTree<TestLeaf>.cornerIndex(of: grid), 3)
        let row = [NSRect(x: 0, y: 0, width: 10, height: 10), NSRect(x: 30, y: 0, width: 10, height: 10)]
        XCTAssertEqual(PaneTree<TestLeaf>.cornerIndex(of: row), 1, "level: rightmost wins")
        let stack = [NSRect(x: 0, y: 0, width: 10, height: 10), NSRect(x: 0, y: 30, width: 10, height: 10)]
        XCTAssertEqual(PaneTree<TestLeaf>.cornerIndex(of: stack), 1, "height beats everything")
        XCTAssertEqual(PaneTree<TestLeaf>.cornerIndex(of: [NSRect(x: 5, y: 5, width: 1, height: 1)]), 0)
    }
}
