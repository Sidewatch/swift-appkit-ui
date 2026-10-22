//
//  LateToolTip.swift
//  AppKitViews
//
//  A tooltip whose text is asked for only when AppKit is about to show it.
//
//  Created by David Sherlock on 10/22/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A tooltip over a view's whole bounds whose text is asked for only when AppKit is about to show
/// it — for text that costs something to work out (a `git` run, a file read), which a list must
/// not pay for every row it lays out or scrolls past. It follows the view as it resizes, and it
/// adds and removes only its own tooltip rectangle, never the view's others.
///
/// AppKit does not retain a tooltip's owner, so whoever creates one keeps it, and calls
/// ``remove()`` (or drops the last reference) when the view shows something else:
///
/// ```swift
/// lateTip?.remove()
/// lateTip = expensive ? LateToolTip(on: cell) { reason(for: item) } : nil
/// ```
@MainActor
public final class LateToolTip: NSObject, NSViewToolTipOwner {
    /// The view the tooltip covers; nil once it is gone.
    public private(set) weak var view: NSView?
    private let text: () -> String?
    /// The tooltip rectangle AppKit handed back; nil once removed.
    private(set) var tag: NSView.ToolTipTag?
    private var frameObserver: NSObjectProtocol?

    /// Covers `view`'s bounds with a tooltip whose words `text` gives when it is about to show;
    /// nil or empty shows none. `text` is not called until then.
    public init(on view: NSView, text: @escaping () -> String?) {
        self.view = view
        self.text = text
        super.init()
        register()
        view.postsFrameChangedNotifications = true
        frameObserver = NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification, object: view, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.register() }
        }
    }

    isolated deinit {
        if let frameObserver { NotificationCenter.default.removeObserver(frameObserver) }
        if let tag { view?.removeToolTip(tag) }
    }

    /// Takes the tooltip off the view; it shows nothing more and follows no more resizes.
    public func remove() {
        if let frameObserver { NotificationCenter.default.removeObserver(frameObserver) }
        frameObserver = nil
        if let tag { view?.removeToolTip(tag) }
        tag = nil
    }

    /// The words the tooltip would show now (asking for them), "" for none.
    public var currentText: String { text() ?? "" }

    /// Puts the rectangle over the view's bounds as they are now, replacing the previous one.
    private func register() {
        guard let view else { return }
        if let tag { view.removeToolTip(tag) }
        tag = view.addToolTip(view.bounds, owner: self, userData: nil)
    }

    /// AppKit asks as the tooltip is about to show.
    public func view(_ view: NSView, stringForToolTip tag: NSView.ToolTipTag, point: NSPoint, userData data: UnsafeMutableRawPointer?)
        -> String
    {
        currentText
    }
}
