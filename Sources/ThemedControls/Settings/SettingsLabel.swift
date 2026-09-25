//
//  SettingsLabel.swift
//  ThemedControls
//
//  A settings text label that re-reads its `Theme` color on every `ThemedControls.paletteDidChange`, so a palette
//  switch with the window open re-tints it even when its pane is off screen (the tab it isn't
//  on).
//
//  Created by David Sherlock on 9/5/26.
//

import AppKit

/// A settings text label that re-reads its `Theme` color on every
/// `ThemedControls.paletteDidChange`, so a palette switch with the window open re-tints it even
/// when its pane is off screen (the tab it isn't on). Three roles: `primary` for
/// a row caption, `secondary` for a section header, `tertiary` for a footnote.
public final class SettingsLabel: NSTextField {

    /// Which `Theme` text tone the label carries.
    public enum Role { case primary, secondary, tertiary }

    private let role: Role
    /// A `primary` caption dims with the control it labels; the setter records it
    /// so a mid-flight theme change re-applies the dimmed tone, not the live one.
    private var dimmed = false

    /// Builds a flat, non-editable label. `wrapping` gives a footnote that flows
    /// to several lines (the caller sets `preferredMaxLayoutWidth`); otherwise it
    /// is a single line that truncates rather than pushing its row's control off.
    public init(role: Role, wrapping: Bool = false) {
        self.role = role
        super.init(frame: .zero)
        isEditable = false
        isBordered = false
        isBezeled = false
        drawsBackground = false
        isSelectable = false
        if wrapping {
            (cell as? NSTextFieldCell)?.wraps = true
            (cell as? NSTextFieldCell)?.isScrollable = false
            lineBreakMode = .byWordWrapping
        } else {
            usesSingleLineMode = true
            lineBreakMode = .byTruncatingTail
        }
        translatesAutoresizingMaskIntoConstraints = false
        applyThemeColor()
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged),
                                               name: ThemedControls.paletteDidChange, object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { NotificationCenter.default.removeObserver(self) }

    /// Dims (or restores) a `primary` caption; a no-op tone shift for the other
    /// roles, which never sit against a disabled control.
    public func setDimmed(_ d: Bool) { dimmed = d; applyThemeColor() }

    @objc private func themeChanged() { applyThemeColor() }

    private func applyThemeColor() {
        switch role {
        case .primary:   textColor = dimmed ? ThemedControls.palette.foreground.withAlphaComponent(0.35) : ThemedControls.palette.foreground
        case .secondary: textColor = ThemedControls.palette.statusText
        case .tertiary:  textColor = ThemedControls.palette.statusText.withAlphaComponent(0.85)
        }
    }
}
