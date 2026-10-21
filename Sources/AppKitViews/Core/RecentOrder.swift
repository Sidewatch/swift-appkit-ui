//
//  RecentOrder.swift
//  AppKitViews
//
//  Most-recently-used order over a set of items that come and go.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Items in most-recently-used order, by a STABLE identity (a UUID, never an object address, which
/// is reused once an object is freed and would hand a new item an old item's rank). Removing an item
/// that closes keeps the list to what exists.
public struct RecentOrder<ID: Hashable & Sendable>: Sendable, Equatable {
    /// The identities, most recent first.
    public private(set) var ids: [ID] = []

    /// An empty order.
    public init() {}

    /// `id` became the most recent.
    public mutating func touch(_ id: ID) {
        ids.removeAll { $0 == id }
        ids.insert(id, at: 0)
    }

    /// `id` is gone (its tab closed).
    public mutating func remove(_ id: ID) { ids.removeAll { $0 == id } }

    /// Forgets everything not in `present` (the tabs that exist now).
    public mutating func keep(only present: Set<ID>) { ids.removeAll { !present.contains($0) } }

    /// The most recent of `present`, nil when none of them was ever used.
    public func mostRecent(among present: [ID]) -> ID? {
        let set = Set(present)
        return ids.first { set.contains($0) }
    }

    /// `present` in most-recently-used order, the never-used ones after, in their given order.
    public func ordered(_ present: [ID]) -> [ID] {
        let set = Set(present)
        let used = ids.filter { set.contains($0) }
        let usedSet = Set(used)
        return used + present.filter { !usedSet.contains($0) }
    }
}
