//
//  ThemedScrollView.swift
//  ThemedControls
//
//  An `NSScrollView` whose scroller knob follows the app THEME instead of the system
//  appearance.
//
//  Created by David Sherlock on 7/17/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// An `NSScrollView` whose scroller knob follows the palette's light/dark instead of the system's,
/// which otherwise paints a dark knob on a dark theme under a light system.
///
/// Native levers only: forced `.overlay` style (a legacy scroller's reserved track paints a
/// mismatched gutter on a dark theme — this deliberately overrides "always show"), a themed
/// `scrollerKnobStyle`, and a pinned `appearance`. Must not draw a custom knob: a flat pill looks
/// cheaper than AppKit's shaded, hover-aware one.
public final class ThemedScrollView: NSScrollView {

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        scrollerStyle = .overlay   // no reserved track strip — matches the sidebar
        // Uniform auto-hide so every themed scroll view renders the SAME thin overlay
        // knob. Left at the default (false), an overlay scroller stays shown in its
        // wider expanded form — so a split with one auto-hiding pane and one default
        // pane showed two different scroller widths side by side.
        autohidesScrollers = true
        applyThemeChrome()
        NotificationCenter.default.addObserver(
            self, selector: #selector(themeChanged), name: ThemedControls.paletteDidChange, object: nil
        )
    }

    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

    deinit { NotificationCenter.default.removeObserver(self) }

    /// Re-asserts overlay on every tile: a heavily re-laid-out host reverts the scroller to the
    /// system-preferred (legacy) style each time, which a one-shot assignment cannot hold. The
    /// `!=` guard stops the set, which itself tiles, from recursing.
    public override func tile() {
        if scrollerStyle != .overlay { scrollerStyle = .overlay }
        super.tile()
    }

    @objc private func themeChanged() { applyThemeChrome() }

    /// Reads the live palette into the knob style and appearance. `.light` is a LIGHT knob, the
    /// one for a dark background; the matching `.darkAqua` keeps AppKit's knob shading right.
    private func applyThemeChrome() {
        let isDark = ThemedControls.palette.isDark
        scrollerKnobStyle = isDark ? .light : .dark
        appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
    }
}
