//
//  ThemedPillButton.swift
//  ThemedControls
//
//  The app's text button — the composer's "Send ⏎" pill made shared.
//
//  Created by David Sherlock on 9/3/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A text button drawn as a soft tinted pill — accent for a row's main action, foreground-neutral
/// for secondary ones — where a stock `NSButton`'s system bezel ignores the palette. Re-tints on
/// `ThemedControls.paletteDidChange`; open so a subclass can add a closure action.
open class ThemedPillButton: NSButton {
    /// Accent tint for the main action of a row; neutral for the rest.
    open var prominent = true { didSet { applyTheme() } }

    /// Creates a pill titled `title` that sends `action` to `target`.
    public convenience init(title: String, target: AnyObject? = nil, action: Selector? = nil) {
        self.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
    }
    public override init(frame: NSRect) { super.init(frame: frame); setup() }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    private func setup() {
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = 5
        layer?.borderWidth = 1
        setButtonType(.momentaryPushIn)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 22).isActive = true
        widthAnchor.constraint(greaterThanOrEqualToConstant: 62).isActive = true
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme),
                                               name: ThemedControls.paletteDidChange, object: nil)
        applyTheme()
    }

    open override var title: String { didSet { applyTheme() } }
    /// A disabled pill dims to 40%, as the stock bezel greys out; a bright one reads as clickable.
    open override var isEnabled: Bool { didSet { applyTheme() } }
    private var enabledAlpha: CGFloat { isEnabled ? 1 : 0.4 }
    private var restingFillAlpha: CGFloat { (ThemedControls.palette.isDark ? 0.16 : 0.12) * enabledAlpha }

    open override var intrinsicContentSize: NSSize {
        let s = super.intrinsicContentSize
        return NSSize(width: max(62, s.width + 18), height: 22)
    }

    private var tint: NSColor { prominent ? ThemedControls.palette.accent : ThemedControls.palette.foreground }

    /// Repaints title, fill and border from the palette; subclasses call super.
    @objc open func applyTheme() {
        let para = NSMutableParagraphStyle(); para.alignment = .center
        attributedTitle = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: tint.withAlphaComponent(enabledAlpha),
            .paragraphStyle: para,
        ])
        layer?.backgroundColor = tint.withAlphaComponent(restingFillAlpha).cgColor
        layer?.borderColor = tint.withAlphaComponent(0.35 * enabledAlpha).cgColor
    }

    /// Pressed: a deeper fill, the way the system bezel darkens.
    open override func highlight(_ flag: Bool) {
        super.highlight(flag)
        layer?.backgroundColor = tint.withAlphaComponent(flag ? 0.32 : restingFillAlpha).cgColor
    }
}
