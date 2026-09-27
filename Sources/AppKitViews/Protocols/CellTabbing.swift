//
//  CellTabbing.swift
//  AppKitViews
//
//  Tab and ⇧Tab walk a table's editable cells, so an edit never needs the mouse.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A table whose editable cells can be walked with Tab and ⇧Tab.
///
/// A cell here is a real `NSTextField` inside a table row, and AppKit's own key-view loop does
/// not join those up: tabbing out of one commits it and lands somewhere else entirely. So the
/// table answers `editableCells` — every cell it will open, in reading order — and this walks
/// that list.
@MainActor public protocol CellTabbing: NSView {
    /// Every cell that opens for editing, in reading order: left to right, top to bottom.
    var editableCells: [CellPosition] { get }
    /// Opens `position` for editing, if it is still there.
    func beginEditing(_ position: CellPosition)
}

extension CellTabbing {
    /// Opens `position` once the rows it names exist.
    ///
    /// The move cannot be a plain `makeFirstResponder`: committing the edit rewrites the model
    /// and the table RE-RENDERS from it, throwing away the very view the move was aimed at. And
    /// that render can be a turn late where the host defers it, so a miss is retried before
    /// being given up on.
    public func beginEditingWhenReady(_ position: CellPosition, attemptsLeft: Int = 2) {
        DispatchQueue.main.async { [self] in
            beginEditing(position)
            guard attemptsLeft > 1, !isEditing(position) else { return }
            beginEditingWhenReady(position, attemptsLeft: attemptsLeft - 1)
        }
    }

    /// Whether a field of this table currently holds the keyboard. The window lends one field
    /// editor to whichever field is being edited, so the test is whether that editor's field is
    /// inside this view.
    public func isEditing(_ position: CellPosition) -> Bool {
        guard let editor = window?.firstResponder as? NSTextView,
            let field = editor.delegate as? NSView
        else { return false }
        return field.isDescendant(of: self)
    }

    /// The cell after (or before) `current`, or nil at either end.
    ///
    /// Tab STOPS at the edges rather than wrapping, so a held Tab cannot silently start over at
    /// the top of the table — which reads as the keyboard having jumped somewhere at random.
    public func cell(after current: CellPosition, forward: Bool) -> CellPosition? {
        let cells = editableCells
        guard let i = cells.firstIndex(of: current) else { return nil }
        let next = forward ? i + 1 : i - 1
        return cells.indices.contains(next) ? cells[next] : nil
    }
}
