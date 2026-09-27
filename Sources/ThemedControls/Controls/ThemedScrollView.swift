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

/// An `NSScrollView` whose scroller knob follows the app THEME instead of the
/// system appearance.
///
/// AppKit picks the knob's light/dark treatment from the SYSTEM setting, which is
/// the wrong signal here: Sidewatch's theme is chosen independently of it. Run a
/// dark theme under a light system (or the reverse) and the knob is painted for a
/// surface that isn't there — a dark knob on a dark editor, effectively invisible.
///
/// Three native levers, no custom drawing:
///  - `scrollerStyle = .overlay` — the load-bearing one. A LEGACY scroller (system
///    "Show scroll bars: Always", or Automatic with a mouse attached) reserves a
///    solid track strip down the edge; `NSScroller` paints that slot itself, and on
///    a dark theme it reads as a mismatched brown/tan gutter against the content —
///    the artefact the file tree never shows, because the sidebar already forces
///    overlay. Overlay has no reserved track: a floating knob that auto-hides, so
///    every scroll view matches the sidebar's clean edge. (This overrides the system
///    "always show" pref app-wide, a deliberate look choice — the sidebar set the
///    precedent and the whole app now follows it.)
///  - `scrollerKnobStyle` themes the floating knob.
///  - `appearance` pins the knob's light/dark treatment to the THEME, not the system
///    setting — a dark theme under a light system would otherwise paint the knob for
///    a surface that isn't there.
///
/// A custom `NSScroller` subclass that draws its own tinted knob was tried and
/// REVERTED — a flat custom pill looks cheaper than AppKit's shaded, hover-aware
/// native knob, so tinting is a net loss (exactly the trade this note first warned of).
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

    /// AppKit calls `tile()` on every scroller layout, and a heavily re-laid-out host
    /// (the editor — minimap, sticky scroll, diff layout all re-tile) reverts the
    /// scroller to the system-PREFERRED style (legacy with a mouse attached) each
    /// time, which repaints the brown track strip a one-shot assignment can't hold.
    /// Re-assert overlay here; the `!=` guard stops the set (which itself tiles) from
    /// recursing. Deliberate-legacy scrollers use a different class (`ZoomingScrollView`),
    /// so this never fights them.
    public override func tile() {
        if scrollerStyle != .overlay { scrollerStyle = .overlay }
        super.tile()
    }

    @objc private func themeChanged() { applyThemeChrome() }

    /// Reads the live palette, so an imported VS Code theme flips both exactly like
    /// the built-ins. `.light` knob = a LIGHT-colored knob, the one for a dark
    /// background; the matching `.darkAqua` appearance keeps AppKit's own knob
    /// shading on the right side.
    private func applyThemeChrome() {
        let isDark = ThemedControls.palette.isDark
        scrollerKnobStyle = isDark ? .light : .dark
        appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
    }
}
