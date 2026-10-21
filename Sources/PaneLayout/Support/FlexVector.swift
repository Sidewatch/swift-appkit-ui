//
//  FlexVector.swift
//  PaneLayout
//
//  The rules for an axis's flex vector: when one is valid, and what survives when members drop out.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import CoreGraphics

/// The size truth of a ``PaneAxisView``: one positive share per member, the shares summing to the member
/// count (so all-ones is equal widths). These are the checks a restored or rebuilt vector must pass.
public enum FlexVector {
    /// How far a sum may drift from the member count and still be valid (floating-point drift).
    public static let tolerance: CGFloat = 0.01

    /// Whether `flexes` is a valid vector for `count` members: as many shares, every one positive, the
    /// sum within ``tolerance`` of `count`.
    public static func isValid(_ flexes: [CGFloat], count: Int) -> Bool {
        flexes.count == count && flexes.allSatisfy { $0 > 0 } && abs(flexes.reduce(0, +) - CGFloat(count)) < tolerance
    }

    /// The shares of the members at `kept` (indices into `flexes`, in order), rescaled to sum to their
    /// new count — what an axis keeps when some members could not be saved or rebuilt, so the survivors
    /// keep their proportions instead of resetting to equal. Nil when an index is out of range or a kept
    /// share is not positive.
    public static func keeping(_ flexes: [CGFloat], at kept: [Int]) -> [CGFloat]? {
        guard kept.allSatisfy({ flexes.indices.contains($0) }) else { return nil }
        let shares = kept.map { flexes[$0] }
        let sum = shares.reduce(0, +)
        guard !shares.isEmpty, shares.allSatisfy({ $0 > 0 }), sum > 0 else { return nil }
        let scale = CGFloat(shares.count) / sum
        return shares.map { $0 * scale }
    }
}
