//
//  SettingsSeparatorView.swift
//  ThemedControls
//
//  The hairline between two card rows, inset to the card's text margin so it reads as a divider
//  between rows rather than a cut across the card.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// The hairline between two card rows, inset to the card's text margin so it
/// reads as a divider between rows rather than a cut across the card.
public final class SettingsSeparatorView: NSView {

    /// Creates a separator already opted out of autoresizing constraints: a kept zero-height frame
    /// constraint breaks the card's row chain and collapses the card to its first row.
    public init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        NotificationCenter.default.addObserver(
            self, selector: #selector(themeChanged),
            name: ThemedControls.paletteDidChange, object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { NotificationCenter.default.removeObserver(self) }

    public override func draw(_ dirtyRect: NSRect) {
        let inset = SettingsMetrics.cardInset
        // `rowSeparator`, not `ThemedControls.palette.border` — the border colour is tuned to sit on
        // the page background and would land darker than the card fill it's drawn
        // over, reading as a crack rather than a divider.
        ThemedControls.palette.rowSeparator.setFill()
        NSRect(x: inset, y: 0, width: max(0, bounds.width - inset * 2), height: bounds.height).fill()
    }

    @objc private func themeChanged() { needsDisplay = true }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}
