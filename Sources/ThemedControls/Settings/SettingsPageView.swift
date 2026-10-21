//
//  SettingsPageView.swift
//  ThemedControls
//
//  A settings page whose fill follows the palette.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A settings pane's page: a layer-backed view whose fill tracks the palette. The
/// `CGColor` is re-applied on `ThemedControls.paletteDidChange` and on an appearance flip, since
/// a layer color snapshot would otherwise freeze at the palette it was set under.
public final class SettingsPageView: NSView {

    /// A page filling `frameRect`.
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        applyTheme()
        NotificationCenter.default.addObserver(
            self, selector: #selector(themeChanged),
            name: ThemedControls.paletteDidChange, object: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func themeChanged() { applyTheme() }

    private func applyTheme() { styleLayer(background: SettingsMetrics.pageBackground) }

    override public func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyTheme()
    }
}
