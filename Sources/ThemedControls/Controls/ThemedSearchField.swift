//
//  ThemedSearchField.swift
//  ThemedControls
//
//  A theme-aware search/filter input matching the Find-in-Project field: a rounded
//  `ThemedControls.palette.border` container over an elevated surface, holding a *borderless* text field (the
//  system `NSSearchField` bezel ignores the app theme, so we don't use it) with a leading
//  magnifier glyph.
//
//  Created by David Sherlock on 7/18/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A theme-aware search/filter input: a rounded palette-bordered box over an elevated surface
/// holding a *borderless* text field and a leading magnifier (the `NSSearchField` bezel ignores
/// the palette). Fires `onChange` live on each keystroke.
open class ThemedSearchField: NSView, NSTextFieldDelegate {
    /// Called on every edit with the current text.
    open var onChange: ((String) -> Void)?
    /// Called on Escape. Hosts that reveal the field on demand use this to dismiss
    /// it; leaving it nil lets Escape fall through to whatever handled it before.
    open var onCancel: (() -> Void)?
    /// Fired on Return (the field editor's `insertNewline:`) — "next match" for a find bar.
    open var onSubmit: (() -> Void)?

    private let icon = NSImageView()
    private let field = NSTextField()

    /// The text in the field; setting it does not fire `onChange`.
    open var stringValue: String {
        get { field.stringValue }
        set { field.stringValue = newValue }
    }
    /// The dimmed prompt shown while the field is empty.
    open var placeholder: String = "" {
        didSet { applyPlaceholder() }
    }

    open override var intrinsicContentSize: NSSize { NSSize(width: NSView.noIntrinsicMetric, height: 26) }

    /// Creates a field showing `placeholder` while empty.
    public init(placeholder: String = "") {
        self.placeholder = placeholder
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1

        icon.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
        icon.imageScaling = .scaleProportionallyDown
        icon.translatesAutoresizingMaskIntoConstraints = false

        field.font = .systemFont(ofSize: 12)

        field.disableSystemTextIntelligence()
        field.focusRingType = .none
        field.isBordered = false
        field.drawsBackground = false
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false
        if let cell = field.cell as? NSTextFieldCell {
            cell.usesSingleLineMode = true
            cell.isScrollable = true
            cell.lineBreakMode = .byTruncatingTail
        }

        addSubview(icon)
        addSubview(field)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 7),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 12),
            icon.heightAnchor.constraint(equalToConstant: 12),
            field.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 5),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -7),
            field.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        applyTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: ThemedControls.paletteDidChange, object: nil)
    }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    /// Moves keyboard focus into the inner text field. The wrapper isn't itself a
    /// control, so `makeFirstResponder(themedSearchField)` would do nothing.
    open func focus() { window?.makeFirstResponder(field) }

    open func control(_ control: NSControl, textView: NSTextView, doCommandBy sel: Selector) -> Bool {
        if sel == #selector(NSResponder.cancelOperation(_:)), let onCancel { onCancel(); return true }
        if sel == #selector(NSResponder.insertNewline(_:)), let onSubmit { onSubmit(); return true }
        return false
    }

    @objc private func themeChanged() { applyTheme() }

    private func applyTheme() {
        layer?.backgroundColor = ThemedControls.palette.elevatedSurface(dark: 0.07, light: 0.04).cgColor
        layer?.borderColor = ThemedControls.palette.border.cgColor
        icon.contentTintColor = ThemedControls.palette.sidebarText.withAlphaComponent(0.45)
        field.textColor = ThemedControls.palette.foreground
        // Match the caret/selection to the theme's light/dark mode.
        appearance = NSAppearance(named: ThemedControls.palette.isDark ? .darkAqua : .aqua)
        applyPlaceholder()
    }

    private func applyPlaceholder() {
        field.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: ThemedControls.palette.sidebarText.withAlphaComponent(0.45),
            ])
    }

    open func controlTextDidChange(_ obj: Notification) {
        onChange?(field.stringValue)
    }
}
