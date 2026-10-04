//
//  NSPasteboard+Receipt.swift
//  ThemedControls
//
//  Copying with the heads-up receipt that says what was copied.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

public extension NSPasteboard {
    /// Copies `text` and confirms it with the heads-up capsule over `window` — for commands that
    /// copy something the person cannot see being copied (a path, a tree, a prompt). Plain ⌘C and
    /// copy-on-select stay silent: a receipt on every copy would be noise.
    func copyAndConfirm(_ text: String, receipt: String, in window: NSWindow?) {
        copy(text)
        HeadsUpDisplay.show(receipt, systemImage: "doc.on.doc", in: window)
    }
}
