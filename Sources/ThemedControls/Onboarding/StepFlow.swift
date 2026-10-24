//
//  StepFlow.swift
//  ThemedControls
//
//  Where a step-by-step guide stands: which step, and what Back, Continue and Skip do from it.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The position in a guide of `count` steps, and the moves between them. Pure state, so the rules —
/// no Back from the first step, Continue on the last finishes, Skip finishes from anywhere — are
/// tested without a window. ``StepFlowView`` drives it.
nonisolated public struct StepFlow: Equatable, Sendable {
    /// How a guide ended.
    public enum Ending: Equatable, Sendable {
        /// Continue on the last step: every step was seen.
        case completed
        /// Skip: the steps not yet seen keep their defaults.
        case skipped
    }

    /// The number of steps; at least one.
    public let count: Int
    /// The step showing, from 0.
    public private(set) var index: Int
    /// How the guide ended, or nil while it runs.
    public private(set) var ending: Ending?

    /// A guide of `count` steps (at least one) at its first step.
    public init(count: Int) {
        self.count = max(1, count)
        index = 0
    }

    /// Whether the first step is showing: there is no Back.
    public var isFirst: Bool { index == 0 }
    /// Whether the last step is showing: Continue finishes.
    public var isLast: Bool { index == count - 1 }
    /// Whether the guide has ended.
    public var isFinished: Bool { ending != nil }

    /// Continue: the next step, or the end after the last. Nothing once finished.
    public mutating func advance() {
        guard !isFinished else { return }
        if isLast { ending = .completed } else { index += 1 }
    }

    /// Back: the previous step. Nothing on the first, or once finished.
    public mutating func back() {
        guard !isFinished, !isFirst else { return }
        index -= 1
    }

    /// Skip: the end, from any step. Nothing once finished.
    public mutating func skip() {
        guard !isFinished else { return }
        ending = .skipped
    }
}
