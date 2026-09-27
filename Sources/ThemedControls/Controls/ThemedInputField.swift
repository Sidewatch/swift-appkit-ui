//
//  ThemedInputField.swift
//  ThemedControls
//
//  Shared theming for Settings text inputs.
//
//  Created by David Sherlock on 7/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// Shared theming for Settings text inputs. The system `NSTextField` / `NSSecureTextField`
/// bezel ignores the app theme — it paints a system-tinted box that clashes with a warm
/// palette (the "brownish field" bug) — so these fields are **borderless** and draw their
/// own rounded `ThemedControls.palette.border` box over an elevated surface, with themed text + caret.
/// Mirrors `ThemedSearchField`'s approach; re-tints on `.themeDidChange`.
private enum ThemedInputStyle {
    public static func apply(_ field: NSTextField) {
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.wantsLayer = true
        field.layer?.cornerRadius = 5
        field.layer?.borderWidth = 1
        refresh(field)
    }
    public static func refresh(_ field: NSTextField) {
        field.layer?.backgroundColor = ThemedControls.palette.elevatedSurface(dark: 0.07, light: 0.04).cgColor
        // `rowSeparator`, not `ThemedControls.palette.border`: these sit inside a settings card, so
        // the recessed page-edge colour drew a near-black rectangle on a lifted
        // surface. Same reasoning as the card's row dividers — see Theme+Surfaces.
        field.layer?.borderColor = ThemedControls.palette.rowSeparator.cgColor
        field.textColor = ThemedControls.palette.foreground
        // Caret + selection follow the THEME's light/dark mode, not the system's.
        field.appearance = NSAppearance(named: ThemedControls.palette.isDark ? .darkAqua : .aqua)
    }
}

/// Insets the text a few points so it doesn't hug the rounded border (a right-aligned
/// number would otherwise touch the edge), and centres the single line in the box.
/// Drawing/editing rects only — no layout.
///
/// The vertical part matters because these fields are given an explicit height (the themed
/// box needs one) that is taller than a line of 12pt text. A borderless, scrollable cell
/// lays its line from the TOP of the rect it is handed, so the number sat 3.5pt above the
/// centre of its own box — visible as soon as you look for it, and `--dump-settings` could
/// not see it because the box's own border dominated the ink it was measuring.
///
/// The slack is MEASURED, never a tuned constant: `cellSize(forBounds:)` reports the line's
/// natural height and `insetBy` takes half the remainder off each end, so the text is centred
/// by construction at any font size or box height. (Hand-tuning that number is the mistake
/// recorded against the status bar's "ctx" cap.)
private final class PaddedFieldCell: NSTextFieldCell {
    private static let dx: CGFloat = 6

    /// `rect` inset horizontally for padding and vertically so a single line sits centred.
    private func textRect(_ rect: NSRect) -> NSRect {
        let padded = rect.insetBy(dx: Self.dx, dy: 0)
        let natural = super.cellSize(forBounds: padded).height
        guard natural > 0, natural < padded.height else { return padded }
        return padded.insetBy(dx: 0, dy: ((padded.height - natural) / 2).rounded())
    }

    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        super.drawingRect(forBounds: textRect(rect))
    }
    // The editing rects get the same treatment, or the number jumps the moment it is clicked.
    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText,
                       delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: textRect(rect), in: controlView,
                   editor: textObj, delegate: delegate, event: event)
    }
    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText,
                         delegate: Any?, start: Int, length: Int) {
        super.select(withFrame: textRect(rect), in: controlView,
                     editor: textObj, delegate: delegate, start: start, length: length)
    }
}

/// Theme-aware single-line text input for the Settings panes.
open class ThemedInputField: NSTextField {
    public convenience init() { self.init(frame: .zero) }
    public override init(frame frameRect: NSRect) { super.init(frame: frameRect); setup() }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let padded = PaddedFieldCell()
        padded.isEditable = true
        padded.isSelectable = true
        padded.isScrollable = true
        padded.usesSingleLineMode = true
        cell = padded
        ThemedInputStyle.apply(self)
        disableSystemTextIntelligence()
        NotificationCenter.default.addObserver(self, selector: #selector(reTheme),
                                               name: ThemedControls.paletteDidChange, object: nil)
    }
    deinit { NotificationCenter.default.removeObserver(self) }
    @objc private func reTheme() { ThemedInputStyle.refresh(self) }
}

/// Secure (password) counterpart — the Usage session-key field. Keeps the masking cell
/// (`NSSecureTextFieldCell`), so no padded cell here; only the themed chrome is applied.
public final class ThemedSecureInputField: NSSecureTextField {
    public convenience init() { self.init(frame: .zero) }
    public override init(frame frameRect: NSRect) { super.init(frame: frameRect); setup() }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        ThemedInputStyle.apply(self)
        disableSystemTextIntelligence()
        NotificationCenter.default.addObserver(self, selector: #selector(reTheme),
                                               name: ThemedControls.paletteDidChange, object: nil)
    }
    deinit { NotificationCenter.default.removeObserver(self) }
    @objc private func reTheme() { ThemedInputStyle.refresh(self) }
}
