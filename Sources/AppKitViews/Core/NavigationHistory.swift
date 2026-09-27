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
/// A **browser two-stack model**, not a cursor into one list: `back` holds where you came
/// from, `forward` holds what you've backed out of, and any NEW jump clears `forward`
/// because you've branched off the old path. The single-list-with-an-index alternative
/// reads simpler and then gets subtly wrong the moment a jump happens mid-history — the
/// entries after the index have to be dropped anyway, so the stacks say the real shape.
///
/// **Only EXPLICIT jumps should be recorded, and that is the host's job:** a
/// go-to-definition, a quick-open pick, a go-to-line, a search hit, an outline click.
/// Scrolling, typing, arrow keys and tab switches deliberately must not, because a history
/// that records where you DRIFTED stops being an undo for where you CHOSE to go, which is
/// the only thing Back is useful for. This is the line VS Code draws, and the reason its
/// Back key is worth muscle memory.
///
/// Positions are captured at jump time and never revalidated — a file edited or deleted
/// since is handled at restore (clamped / skipped), not by trying to keep the stack live.
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

    public var canGoBack: Bool { !back.isEmpty }
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
