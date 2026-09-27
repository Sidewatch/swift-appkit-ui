//
//  ZoomKeyView.swift
//  AppKitViews
//
//  A container that answers ⌘= / ⌘- / ⌘0 before the main menu, and never leaks a right-click.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A container view that routes ⌘= / ⌘- / ⌘0 to `onZoomKey` through `performKeyEquivalent`,
/// which the window consults BEFORE the main menu. So the content it holds zooms while it is on
/// screen, and a menu item bound to the same keys — a font size, say — keeps working whenever
/// this container is not in the window. `onZoomKey` returns whether it consumed the key, so an
/// already-fully-zoomed-out surface can pass one on.
open class ZoomKeyView: NSView {
    /// Answers a zoom key. Return true to consume it.
    public var onZoomKey: ((ZoomKeyDirection) -> Bool)?

    public override init(frame frameRect: NSRect) { super.init(frame: frameRect) }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    /// A right-click anywhere yields an EMPTY menu rather than nil. Returning nil lets the event
    /// climb the responder chain to whatever sits beneath — for a view stacked over an editor,
    /// that means the editor's Cut / Go to Definition menu opening over an image. A subview that
    /// wants a menu sets its own, which is asked first because the hit view is consulted before
    /// its ancestors.
    open override func menu(for event: NSEvent) -> NSMenu? { NSMenu() }

    open override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.intersection([.command, .option, .control, .shift]) == .command,
            let dir = ZoomKeyDirection(keyChars: event.charactersIgnoringModifiers)
        else {
            return super.performKeyEquivalent(with: event)
        }
        return onZoomKey?(dir) ?? false
    }
}
