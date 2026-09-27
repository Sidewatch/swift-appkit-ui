//
//  NavigationHistory.swift
//  AppKitViews
//
//  Back/forward jump history, plus the last-edit anchor.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Back/forward jump history, plus a last-edit anchor.
///
/// A browser-style two-stack model: `back` holds where you came from, `forward` what you've
/// backed out of, and any new jump clears `forward`. The host records only explicit jumps
/// (go-to-definition, quick open, search hits), never scrolling or typing, so Back undoes
/// where you chose to go. Positions are not revalidated; a stale one is clamped or skipped
/// at restore.
@MainActor public final class NavigationHistory {

    /// - Parameter cap: How many positions to keep. The default is far past the depth anyone
    ///   navigates back through.
    public init(cap: Int = 60) { self.cap = cap }

    /// Where you came from, most recent last.
    public private(set) var back: [DocumentLocation] = []
    /// What you've backed out of, most recent last. Cleared by any new jump.
    public private(set) var forward: [DocumentLocation] = []
    /// The caret position of the most recent text edit, for Go ▸ Last Edit Location.
    /// Overwritten (not stacked) — "the last one" is the whole feature.
    public var lastEdit: DocumentLocation?

    /// Bounded so a long session can't grow the stack without limit; 60 is far past
    /// the depth anyone navigates back through and costs nothing.
    public let cap: Int

    /// Whether Back has somewhere to go, for enabling the menu item.
    public var canGoBack: Bool { !back.isEmpty }
    /// Whether Forward has somewhere to go, for enabling the menu item.
    public var canGoForward: Bool { !forward.isEmpty }

    /// Records `from` as somewhere worth returning to and branches the forward path.
    /// A nil location (untitled buffer, tool/diff tab — nothing with a URL to return to)
    /// records nothing rather than pushing a placeholder that Back would land on.
    public func recordJump(from: DocumentLocation?) {
        guard let from else { return }
        if back.last == from { return }     // coalesce a repeat of the same spot
        back.append(from)
        if back.count > cap { back.removeFirst(back.count - cap) }
        forward.removeAll()
    }

    /// Steps back one position, parking `current` on the forward stack. nil when empty.
    public func goBack(current: DocumentLocation?) -> DocumentLocation? {
        guard let target = back.popLast() else { return nil }
        if let current { forward.append(current) }
        return target
    }

    /// Steps forward one position, returning `current` to the back stack. nil when empty.
    public func goForward(current: DocumentLocation?) -> DocumentLocation? {
        guard let target = forward.popLast() else { return nil }
        if let current { back.append(current) }
        return target
    }

    /// Drops the whole history. A host calls this when its project root changes, since every
    /// position in the stack points into the tree that just went away.
    public func clear() {
        back.removeAll()
        forward.removeAll()
        lastEdit = nil
    }
}
