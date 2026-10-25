//
//  ThemedSlider+Settings.swift
//  ThemedControls
//
//  The Settings value slider and the fixed-width readout beside it.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

public extension ThemedSlider {
    /// The width of a Settings value slider.
    static let settingsWidth: CGFloat = 150

    /// Sets the slider up as a Settings value slider: `min`…`max`, continuous (what it changes is its
    /// own preview), small, ``settingsWidth`` wide, with `ticks` marks below as a scale cue only —
    /// `allowsTickMarkValuesOnly` stays off, so every value between them is still reachable.
    func configureAsSettingsValue(
        min: Double, max: Double, default defaultValue: Double? = nil, ticks: Int, target: AnyObject?, action: Selector
    ) {
        self.defaultValue = defaultValue
        minValue = min
        maxValue = max
        isContinuous = true
        controlSize = .small
        numberOfTickMarks = ticks
        tickMarkPosition = .below
        self.target = target
        self.action = action
        pinSize(width: Self.settingsWidth)
    }
}

public extension NSTextField {
    /// Styles a label as the readout beside a Settings value slider ("12 pt"): 12 pt secondary text,
    /// right-aligned, and a FIXED `width` wide enough for the longest value, so the slider never
    /// shuffles sideways as the number's width changes.
    func styleAsSliderReadout(width: CGFloat) {
        font = .systemFont(ofSize: 12)
        textColor = .secondaryLabelColor
        alignment = .right
        pinSize(width: width)
    }
}
