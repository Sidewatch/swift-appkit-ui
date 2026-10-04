//
//  ThemedIconButton.swift
//  ThemedControls
//
//  The bars' icon button: an SF Symbol on a soft rounded hover fill, accent while on.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// An SF Symbol button for toolbars and bars, 22×22 unless given a side: no bezel at rest, a soft rounded fill under
/// the pointer and a deeper one while pressed, and the accent (glyph and a faint fill) while
/// `isOn`. Every colour comes from `ThemedControls.palette` and is re-read on
/// `ThemedControls.paletteDidChange`, where a stock borderless `NSButton` keeps the system's grey
/// and shows no hover at all.
open class ThemedIconButton: NSButton {
    /// The default side of the square button, in points.
    public static let side: CGFloat = 22
    /// This button's side.
    public private(set) var side: CGFloat = ThemedIconButton.side

    /// Accent glyph and fill: the toggle this button stands for is engaged.
    open var isOn = false { didSet { applyTheme() } }
    /// The glyph's colour at rest; nil means the palette's status text.
    open var restingTint: NSColor? { didSet { applyTheme() } }

    private var hovered = false
    private var hoverArea: NSTrackingArea?

    /// Creates a `side`-point square button showing `symbol`, read aloud and shown as a tooltip as
    /// `label`.
    public convenience init(
        symbol: String, label: String, side: CGFloat = ThemedIconButton.side, target: AnyObject? = nil, action: Selector? = nil
    ) {
        self.init(frame: NSRect(x: 0, y: 0, width: side, height: side))
        setSymbol(symbol, label: label)
        toolTip = label
        self.target = target
        self.action = action
    }
    public override init(frame: NSRect) { super.init(frame: frame); setup() }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    private func setup() {
        if frame.width > 0 { side = frame.width }
        isBordered = false
        bezelStyle = .regularSquare
        imagePosition = .imageOnly
        imageScaling = .scaleProportionallyDown
        setButtonType(.momentaryChange)
        wantsLayer = true
        layer?.cornerRadius = side >= 20 ? 5 : 4
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: side),
            heightAnchor.constraint(equalToConstant: side),
        ])
        NotificationCenter.default.addObserver(
            self, selector: #selector(applyTheme), name: ThemedControls.paletteDidChange, object: nil)
        applyTheme()
    }

    /// Swaps the glyph (and its spoken name), keeping the tint.
    open func setSymbol(_ symbol: String, label: String) {
        image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        setAccessibilityLabel(label)
        applyTheme()
    }

    open override var intrinsicContentSize: NSSize { NSSize(width: side, height: side) }

    /// Repaints glyph and fill from the palette and the hover / on state; subclasses call super.
    @objc open func applyTheme() {
        let palette = ThemedControls.palette
        contentTintColor = isOn ? palette.accent : (restingTint ?? palette.statusText)
        layer?.backgroundColor = fill(pressed: false)?.cgColor
    }

    /// The fill behind the glyph: none at rest, faint under the pointer, deeper pressed; the accent
    /// family while on.
    private func fill(pressed: Bool) -> NSColor? {
        let palette = ThemedControls.palette
        let base = isOn ? palette.accent : palette.foreground
        let alpha: CGFloat
        if pressed {
            alpha = palette.isDark ? 0.20 : 0.16
        } else if hovered {
            alpha = palette.isDark ? 0.11 : 0.08
        } else {
            alpha = isOn ? (palette.isDark ? 0.14 : 0.10) : 0
        }
        return alpha == 0 ? nil : base.withAlphaComponent(alpha)
    }

    open override func highlight(_ flag: Bool) {
        super.highlight(flag)
        layer?.backgroundColor = fill(pressed: flag)?.cgColor
    }

    open override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverArea { removeTrackingArea(hoverArea) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect], owner: self)
        addTrackingArea(area)
        hoverArea = area
    }
    open override func mouseEntered(with event: NSEvent) { setHovered(true) }
    open override func mouseExited(with event: NSEvent) { setHovered(false) }
    open override var isHidden: Bool { didSet { if isHidden { setHovered(false) } } }

    private func setHovered(_ flag: Bool) {
        guard hovered != flag else { return }
        hovered = flag
        applyTheme()
    }

    // MARK: - Testing

    /// Drives the hover state as the pointer would, for harnesses.
    public func setHoveredForTesting(_ flag: Bool) { setHovered(flag) }
    /// The fill painted behind the glyph now, nil when clear.
    public var fillForTesting: NSColor? { layer?.backgroundColor.flatMap { NSColor(cgColor: $0) } }
}
