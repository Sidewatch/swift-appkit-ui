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
///
/// With a ``defaultValue``, a double-click puts the slider back to it and sends the action, as a
/// drag there would (the reset audio and video apps give their sliders).
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

    /// The value a double-click restores; nil leaves a double-click to the stock slider.
    public var defaultValue: Double?

    open override func mouseDown(with event: NSEvent) {
        guard event.clickCount == 2, resetToDefault() else { return super.mouseDown(with: event) }
    }

    /// Puts the slider at ``defaultValue`` and sends the action; false when it has none.
    @discardableResult public func resetToDefault() -> Bool {
        guard let defaultValue else { return false }
        doubleValue = defaultValue
        sendAction(action, to: target)
        return true
    }

    /// The filled track takes the palette accent.
    @objc open func applyTheme() {
        trackFillColor = ThemedControls.palette.accent
        needsDisplay = true
    }
}
