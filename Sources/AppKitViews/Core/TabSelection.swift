//
//  TabSelection.swift
//  AppKitViews
//
//  Which tab is selected after one moves or closes.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The selected index of a tab strip through a move and a close, so the SAME tab stays selected when
/// another one shifts it, and a closed selected tab hands over by a stated rule.
public enum TabSelection {
    /// What takes over when the selected tab closes.
    public enum Successor: Sendable {
        /// The tab that slides into its place (its right neighbour), or the new last one.
        case rightNeighbour
        /// The given index when there is one (the most recently used tab), else the left neighbour.
        case recentElseLeft(Int?)
    }

    /// The selected index after the tab at `from` moved to `to`.
    public static func afterMove(from: Int, to: Int, selected: Int) -> Int {
        if selected == from { return to }
        if from < selected, to >= selected { return selected - 1 }
        if from > selected, to <= selected { return selected + 1 }
        return selected
    }

    /// The selected index after the tab at `closed` was removed, leaving `remaining` tabs; nil when none
    /// remain. A tab closed before the selected one shifts the selection down, so it stays on the same
    /// tab; closing the selected tab hands over to `successor` (indices in the remaining tabs).
    public static func afterClosing(_ closed: Int, selected: Int, remaining: Int, successor: Successor) -> Int? {
        guard remaining > 0 else { return nil }
        let index: Int
        if closed == selected {
            switch successor {
            case .rightNeighbour: index = closed
            case .recentElseLeft(let recent): index = recent ?? closed - 1
            }
        } else {
            index = closed < selected ? selected - 1 : selected
        }
        return min(max(index, 0), remaining - 1)
    }
}
