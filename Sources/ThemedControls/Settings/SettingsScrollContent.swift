//
//  SettingsScrollContent.swift
//  ThemedControls
//
//  The scrolling content host for a settings pane.
//
//  Created by David Sherlock on 9/5/26.
//

import AppKit

/// The scrolling content host for a settings pane. Flipped so its sections lay out
/// top-to-bottom (an unflipped documentView would stack them from the bottom and open
/// scrolled to the end).
public final class SettingsScrollContent: NSView {
    public override var isFlipped: Bool { true }
}
