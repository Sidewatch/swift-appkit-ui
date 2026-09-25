//
//  PaneAxisViewTests.swift
//  PaneLayoutTests
//
//  The flex vector is the only size truth, and layout is arithmetic that cannot loop.
//
//  Created by David Sherlock on 9/26/26.
//

import XCTest
import AppKit
@testable import PaneLayout

@MainActor final class PaneAxisViewTests: XCTestCase {
    private func axis(_ orientation: PaneOrientation, members: Int, size: NSSize = NSSize(width: 900, height: 600)) -> PaneAxisView {
        let a = PaneAxisView(orientation: orientation)
        a.frame = NSRect(origin: .zero, size: size)
        a.setMembers((0..<members).map { _ in NSView() })
        a.layoutSubtreeIfNeeded()
        return a
    }

    func testMembersTileTheAxisExactly() {
        let a = axis(.horizontal, members: 3)
        let widths = a.members.map(\.frame.width)
        XCTAssertEqual(widths.reduce(0, +), 900, accuracy: 0.001, "no gap and no overlap")
        for m in a.members { XCTAssertEqual(m.frame.height, 600, accuracy: 0.001, "members fill the cross axis") }
    }

    /// The last member takes the rounding remainder, which is what makes the tiling exact at
    /// widths that do not divide evenly.
    func testAnAwkwardWidthStillTilesExactly() {
        for width in [901.0, 1000.0, 337.0, 7.0] {
            let a = axis(.horizontal, members: 3, size: NSSize(width: width, height: 100))
            XCTAssertEqual(a.members.map(\.frame.width).reduce(0, +), width, accuracy: 0.001, "width \(width)")
            XCTAssertEqual(a.members.last?.frame.maxX ?? 0, width, accuracy: 0.001)
        }
    }

    func testAVerticalAxisStacksFromTheTop() {
        let a = axis(.vertical, members: 2, size: NSSize(width: 400, height: 500))
        XCTAssertTrue(a.isFlipped, "offsets run top-left to bottom-right on both axes")
        XCTAssertEqual(a.members[0].frame.minY, 0, accuracy: 0.001)
        XCTAssertEqual(a.members[1].frame.minY, a.members[0].frame.maxY, accuracy: 0.001)
        XCTAssertEqual(a.members.map(\.frame.height).reduce(0, +), 500, accuracy: 0.001)
    }

    func testFlexesDecideTheShares() {
        let a = axis(.horizontal, members: 2, size: NSSize(width: 1000, height: 100))
        a.setFlexes([1.5, 0.5])
        a.layoutSubtreeIfNeeded()
        XCTAssertEqual(a.members[0].frame.width, 750, accuracy: 1)
        XCTAssertEqual(a.members[1].frame.width, 250, accuracy: 1)
    }

    func testEqualizeGivesEveryMemberTheSameShare() {
        let a = axis(.horizontal, members: 4)
        a.setFlexes([2, 1, 0.5, 0.5])
        a.equalize()
        a.layoutSubtreeIfNeeded()
        XCTAssertEqual(a.flexes, [1, 1, 1, 1])
        let widths = a.members.map(\.frame.width)
        XCTAssertEqual(widths.max()! - widths.min()!, 0, accuracy: 1)
    }

    func testReplacingAMemberKeepsTheSlotsFraction() {
        let a = axis(.horizontal, members: 3)
        a.setFlexes([1.8, 0.6, 0.6])
        let replacement = NSView()
        a.replaceMember(a.members[0], with: replacement)
        XCTAssertEqual(a.flexes, [1.8, 0.6, 0.6], "replace does NOT reset the vector")
        XCTAssertTrue(a.members[0] === replacement)
    }

    func testInsertingAndRemovingResetTheVector() {
        let a = axis(.horizontal, members: 2)
        a.setFlexes([1.7, 0.3])
        a.insertMember(NSView(), at: 1)
        XCTAssertEqual(a.flexes, [1, 1, 1])
        a.setFlexes([1.5, 1.0, 0.5])
        a.removeMember(a.members[2])
        XCTAssertEqual(a.flexes, [1, 1])
    }

    func testAnOutOfRangeInsertIsClampedRatherThanTrapping() {
        let a = axis(.horizontal, members: 2)
        let tail = NSView(), head = NSView()
        a.insertMember(tail, at: 99)
        a.insertMember(head, at: -5)
        XCTAssertTrue(a.members.last === tail)
        XCTAssertTrue(a.members.first === head)
        XCTAssertEqual(a.members.count, 4)
    }

    func testTakeMembersEmptiesTheAxisAndHandsThemBack() {
        let a = axis(.horizontal, members: 3)
        let taken = a.takeMembers()
        XCTAssertEqual(taken.count, 3)
        XCTAssertTrue(a.members.isEmpty)
        XCTAssertTrue(a.flexes.isEmpty)
        XCTAssertTrue(taken.allSatisfy { $0.superview == nil })
    }

    func testRemovingAViewThatIsNotAMemberChangesNothing() {
        let a = axis(.horizontal, members: 2)
        a.removeMember(NSView())
        XCTAssertEqual(a.members.count, 2)
    }

    /// Members are frame-driven, never constraint-driven: that is what makes the layout a pure
    /// function of the vector, so the resize feedback loop cannot happen.
    func testMembersAreFrameDrivenNotConstraintDriven() {
        let a = axis(.horizontal, members: 3)
        for m in a.members {
            XCTAssertTrue(m.translatesAutoresizingMaskIntoConstraints)
            XCTAssertEqual(m.autoresizingMask, [], "the axis assigns every frame itself")
        }
    }

    func testAResizeRelaysOutWithoutChangingTheVector() {
        let a = axis(.horizontal, members: 3)
        a.setFlexes([1.5, 1.0, 0.5])
        a.setFrameSize(NSSize(width: 450, height: 600))
        a.layoutSubtreeIfNeeded()
        XCTAssertEqual(a.flexes, [1.5, 1.0, 0.5], "resizing scales, it never fights the vector")
        XCTAssertEqual(a.members.map(\.frame.width).reduce(0, +), 450, accuracy: 0.001)
    }

    func testAnAxisWithNoMembersLaysOutWithoutTrouble() {
        let a = PaneAxisView(orientation: .horizontal)
        a.frame = NSRect(x: 0, y: 0, width: 300, height: 200)
        a.layoutSubtreeIfNeeded()
        XCTAssertTrue(a.members.isEmpty)
    }

    func testThereIsOneDividerBetweenEachPairAndNoneAtTheEnds() {
        let a = axis(.horizontal, members: 4)
        let dividers = a.subviews.compactMap { $0 as? PaneDividerView }
        XCTAssertEqual(dividers.count, 3)
        // Dividers are added after the members, so they hit-test first.
        let firstDividerIndex = a.subviews.firstIndex { $0 is PaneDividerView }!
        let lastMemberIndex = a.subviews.lastIndex { !($0 is PaneDividerView) }!
        XCTAssertGreaterThan(firstDividerIndex, lastMemberIndex, "the hit strips stay on top")
    }

    func testEachDividerSitsOnItsBoundary() {
        let a = axis(.horizontal, members: 3)
        let dividers = a.subviews.compactMap { $0 as? PaneDividerView }
        for (i, d) in dividers.enumerated() {
            XCTAssertEqual(d.frame.midX, a.members[i].frame.maxX, accuracy: 0.51, "divider \(i)")
            XCTAssertEqual(d.frame.height, a.frame.height, accuracy: 0.001)
        }
    }
}
