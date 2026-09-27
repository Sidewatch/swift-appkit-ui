//
//  ThemedSlider.swift
//  ThemedControls
//
//  A slider whose filled track is the palette accent instead of the system tint.
//
//  Created by David Sherlock on 9/18/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A slider whose filled track is the palette accent instead of the system tint. A stock
/// `NSSlider` paints the filled part of its track in the macOS accent colour, which on a themed
/// Settings pane is the one blue that belongs to no theme. The knob and the tick marks stay the
/// system's: they are neutral, and a hand-drawn knob that is nine-tenths right reads worse than
/// the real one. Re-tints on `paletteDidChange`. A swap from `NSSlider` is a type change.
open class ThemedSlider: NSSlider {
    public override init(frame: NSRect) { super.init(frame: frame); setup() }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    private func setup() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(applyTheme),
            name: ThemedControls.paletteDidChange, object: nil)
        applyTheme()
    }

    /// The filled track takes the palette accent.
    @objc open func applyTheme() {
        trackFillColor = ThemedControls.palette.accent
        needsDisplay = true
    }
}
