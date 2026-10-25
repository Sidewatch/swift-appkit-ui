//
//  ChoiceCardView.swift
//  ThemedControls
//
//  One of a few big, described choices — a card with a symbol, a name and a line of detail,
//  ringed in the accent when picked.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A card for one of a few described choices (a radio button with room to explain itself): an SF
/// Symbol, a name and a wrapped line of detail on the palette's card fill, ringed in the accent
/// while picked. A click, or Space while it has focus, calls ``onPick``; the host sets
/// ``isPicked`` on every card of the group, so the cards hold no group state of their own.
/// VoiceOver reads it as a radio button named by its title.
public final class ChoiceCardView: NSView {

    /// Whether this is the chosen card: the accent ring and a selected radio button.
    public var isPicked = false {
        didSet {
            needsDisplay = true
            setAccessibilityValue(isPicked ? 1 : 0)
        }
    }
    /// The card was clicked (or Space pressed on it).
    public var onPick: (() -> Void)?

    private let symbolView = NSImageView()
    private let titleLabel = SettingsLabel(role: .primary)
    private let detailLabel = SettingsLabel(role: .secondary, wrapping: true)

    /// A card named `title` over `detail`, with `symbol` (an SF Symbol name) beside them, its text
    /// wrapping at `width` points.
    public init(title: String, detail: String, symbol: String, width: CGFloat) {
        super.init(frame: .zero)
        wantsLayer = true
        titleLabel.stringValue = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        detailLabel.stringValue = detail
        detailLabel.font = .systemFont(ofSize: 11)
        symbolView.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        symbolView.symbolConfiguration = .init(pointSize: 20, weight: .regular)
        symbolView.contentTintColor = ThemedControls.palette.accent
        symbolView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        let textWidth = width - Self.padding * 3 - Self.symbolWidth
        detailLabel.preferredMaxLayoutWidth = textWidth
        addSubviewsForAutoLayout(symbolView, titleLabel, detailLabel)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: width),
            symbolView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.padding),
            symbolView.topAnchor.constraint(equalTo: topAnchor, constant: Self.padding),
            symbolView.widthAnchor.constraint(equalToConstant: Self.symbolWidth),
            titleLabel.leadingAnchor.constraint(equalTo: symbolView.trailingAnchor, constant: Self.padding),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Self.padding),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Self.padding),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.widthAnchor.constraint(equalToConstant: textWidth),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            detailLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.padding),
        ])
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        detailLabel.setContentHuggingPriority(.required, for: .vertical)

        setAccessibilityElement(true)
        setAccessibilityRole(.radioButton)
        focusRingType = .none  // until the keyboard brings focus (`showsFocusRing`)
        setAccessibilityLabel(title)
        setAccessibilityHelp(detail)
        setAccessibilityValue(0)
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: ThemedControls.paletteDidChange, object: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { NotificationCenter.default.removeObserver(self) }

    private static let padding: CGFloat = 14
    private static let symbolWidth: CGFloat = 26

    @objc private func themeChanged() {
        symbolView.contentTintColor = ThemedControls.palette.accent
        needsDisplay = true
    }

    /// The ring's colour and width: the accent at 2 pt while picked, a hairline otherwise.
    var ring: (color: NSColor, width: CGFloat) {
        isPicked ? (ThemedControls.palette.accent, 2) : (ThemedControls.palette.rowSeparator, SettingsMetrics.hairline)
    }

    public override func draw(_ dirtyRect: NSRect) {
        let (color, width) = ring
        let path = NSBezierPath(
            roundedRect: bounds.insetBy(dx: width / 2, dy: width / 2), xRadius: SettingsMetrics.cardRadius,
            yRadius: SettingsMetrics.cardRadius)
        SettingsMetrics.cardFill.setFill()
        path.fill()
        color.setStroke()
        path.lineWidth = width
        path.stroke()
    }

    // MARK: - Picking

    public override func mouseUp(with event: NSEvent) {
        guard bounds.contains(convert(event.locationInWindow, from: nil)) else { return }
        pick()
    }

    public override var acceptsFirstResponder: Bool { true }
    public override var canBecomeKeyView: Bool { true }

    /// Whether the focus ring shows: only for focus the keyboard brought (Tab), never for focus
    /// a window or page swap handed over, whose ring beside another card's pick reads as two picks.
    public private(set) var showsFocusRing = false {
        didSet {
            focusRingType = showsFocusRing ? .default : .none
            noteFocusRingMaskChanged()
        }
    }

    public override func becomeFirstResponder() -> Bool {
        let became = super.becomeFirstResponder()
        if became { showsFocusRing = Self.isKeyboardFocus(NSApp?.currentEvent) }
        return became
    }

    public override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned { showsFocusRing = false }
        return resigned
    }

    /// Whether `event` moved focus by keyboard: a key press (Tab, ⇧Tab).
    static func isKeyboardFocus(_ event: NSEvent?) -> Bool { event?.type == .keyDown }

    /// A click takes focus too, so focus never stays on one card while another is picked.
    public override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    public override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == " " { pick() } else { super.keyDown(with: event) }
    }

    public override func accessibilityPerformPress() -> Bool {
        pick()
        return true
    }

    private func pick() { onPick?() }

    public override func drawFocusRingMask() {
        NSBezierPath(roundedRect: bounds, xRadius: SettingsMetrics.cardRadius, yRadius: SettingsMetrics.cardRadius).fill()
    }

    public override var focusRingMaskBounds: NSRect { bounds }
}
