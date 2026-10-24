//
//  CompanionWindowController.swift
//  AppKitViews
//
//  A window that borrows a view from another window — a panel torn off to sit on a second
//  screen — and gives it back.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A window that hosts a view borrowed from another window, filling its content, until the host
/// takes it back with ``release()``. The view moves, it is not copied: whatever it holds (a running
/// shell, its scrollback) comes along and goes back intact.
///
/// The red button does NOT close the window: it calls ``onCloseRequest`` and leaves the decision —
/// usually "put the view back where it came from" — to the host, which then calls ``release()``.
/// So the view is never lost with a window nobody holds. ``frameDescriptor`` is the window's frame
/// as `NSWindow` saves one, for the host to keep across launches.
public final class CompanionWindowController: NSWindowController, NSWindowDelegate {

    /// The red button (or ⌘W) was pressed; the host decides what happens and calls ``release()``.
    public var onCloseRequest: (() -> Void)?
    /// The window became key, for a host that routes commands to whichever window is in front.
    public var onBecameKey: (() -> Void)?

    /// The view being hosted, until it is released.
    public private(set) var hostedView: NSView?

    /// A titled, resizable window of at least `minSize` holding `view` edge to edge, at `frame` (a
    /// saved ``frameDescriptor``) when given, else `defaultFrame`. The window is not shown.
    public init(hosting view: NSView, title: String, frame: String?, defaultFrame: NSRect, minSize: NSSize) {
        let window = NSWindow(
            contentRect: defaultFrame, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = title
        window.isReleasedWhenClosed = false
        window.contentMinSize = minSize
        window.tabbingMode = .disallowed
        if let frame { window.setFrame(from: frame) }
        super.init(window: window)
        window.delegate = self
        let content = NSView()
        window.contentView = content
        view.removeFromSuperview()
        content.addSubview(view)
        view.pinEdges(to: content)
        hostedView = view
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// The window's frame as `NSWindow.frameDescriptor` writes it.
    public var frameDescriptor: String { window?.frameDescriptor ?? "" }

    /// Takes the hosted view out of the window and closes it; the caller puts the view back. Nil
    /// once released.
    @discardableResult
    public func release() -> NSView? {
        guard let view = hostedView else { return nil }
        hostedView = nil
        view.removeFromSuperview()
        window?.delegate = nil
        window?.orderOut(nil)
        window?.close()
        return view
    }

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard hostedView != nil else { return true }
        onCloseRequest?()
        return false
    }

    public func windowDidBecomeKey(_ notification: Notification) { onBecameKey?() }
}
