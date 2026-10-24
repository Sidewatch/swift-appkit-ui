//
//  ThemedActionButton.swift
//  ThemedControls
//
//  A step's call to action: a filled accent capsule, or plain text, with an SF Symbol before or
//  after the title.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A larger button for moving on — a guide's Continue, Back and Skip. `.primary` is a capsule
/// filled with the palette's accent, its title in `onAccent`; `.plain` is the title alone in the
/// muted text tone, brightening to the foreground under the pointer. An optional SF Symbol sits
/// before (`‹ Back`) or after (`Continue ›`) the title. Re-tints on `ThemedControls.paletteDidChange`.
public final class ThemedActionButton: NSButton {

    /// How the button is drawn.
    public enum Style: Sendable {
        /// The accent-filled capsule: the one thing to press.
        case primary
        /// The title alone: a way out or back.
        case plain
    }

    /// Where the symbol sits.
    public enum SymbolPlacement: Sendable {
        case leading, trailing
    }

    /// How the button is drawn.
    public var style: Style { didSet { applyTheme() } }
    /// The SF Symbol beside the title, or nil.
    public var symbol: String? { didSet { applyTheme() } }
    /// Which side of the title the symbol is on.
    public var symbolPlacement: SymbolPlacement { didSet { applyTheme() } }

    /// The capsule's height, in points.
    public static let height: CGFloat = 30

    private var hovering = false { didSet { applyTheme() } }

    /// A button titled `title` in `style`, with `symbol` on the `placement` side, sending `action`
    /// to `target`.
    public init(
        title: String, style: Style, symbol: String? = nil, placement: SymbolPlacement = .trailing, target: AnyObject? = nil,
        action: Selector? = nil
    ) {
        self.style = style
        self.symbol = symbol
        self.symbolPlacement = placement
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        isBordered = false
        wantsLayer = true
        setButtonType(.momentaryPushIn)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: Self.height).isActive = true
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: ThemedControls.paletteDidChange, object: nil)
        applyTheme()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { NotificationCenter.default.removeObserver(self) }

    public override var title: String { didSet { applyTheme() } }
    public override var isEnabled: Bool { didSet { applyTheme() } }

    public override var intrinsicContentSize: NSSize {
        let size = super.intrinsicContentSize
        return NSSize(width: size.width + (style == .primary ? 28 : 12), height: Self.height)
    }

    /// The title's colour as drawn now.
    var titleColor: NSColor {
        let palette = ThemedControls.palette
        let base: NSColor =
            switch style {
            case .primary: palette.onAccent
            case .plain: hovering ? palette.foreground : palette.mutedText
            }
        return base.withAlphaComponent(isEnabled ? 1 : 0.4)
    }

    /// The fill behind the title as drawn now: the accent for `.primary`, none for `.plain`.
    var fillColor: NSColor? {
        guard style == .primary else { return nil }
        let accent = ThemedControls.palette.accent
        return (hovering && isEnabled ? accent.blended(withFraction: 0.12, of: .white) ?? accent : accent)
            .withAlphaComponent(isEnabled ? 1 : 0.4)
    }

    @objc private func applyTheme() {
        attributedTitle = NSAttributedString(
            string: title, attributes: [.font: NSFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: titleColor])
        if let symbol {
            image = .symbol(symbol, pointSize: 11, weight: .semibold)
            imagePosition = symbolPlacement == .leading ? .imageLeading : .imageTrailing
            contentTintColor = titleColor
        } else {
            image = nil
            imagePosition = .noImage
        }
        layer?.cornerRadius = Self.height / 2
        layer?.backgroundColor = fillColor?.cgColor
    }

    // MARK: - Hover

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect], owner: self))
    }

    public override func mouseEntered(with event: NSEvent) { hovering = true }
    public override func mouseExited(with event: NSEvent) { hovering = false }

    public override func highlight(_ flag: Bool) {
        super.highlight(flag)
        layer?.opacity = flag ? 0.8 : 1
    }

    public override func resetCursorRects() { addCursorRect(bounds, cursor: .pointingHand) }
}
