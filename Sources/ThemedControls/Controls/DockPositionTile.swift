//
//  DockPositionTile.swift
//  ThemedControls
//
//  One choice of a `DockPositionPicker`: a small drawing of the window with the panel docked at
//  its position, named underneath.
//
//  Created by David Sherlock on 10/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A window drawn as skeleton bars — rail, sidebar, code lines — with the panel docked at
/// ``position``, and the position's name under it. Ringed in the accent while picked; a click or
/// Space picks it.
public final class DockPositionTile: NSView {
    /// The position this tile draws.
    public let position: DockPosition

    /// Whether this is the chosen tile: the accent ring, the name in the accent, a selected radio button.
    public var isPicked = false {
        didSet {
            needsDisplay = true
            nameLabel.textColor = isPicked ? ThemedControls.palette.accent : ThemedControls.palette.mutedText
            setAccessibilityValue(isPicked ? 1 : 0)
        }
    }

    /// Whether the panel is shown at all: off, its region is drawn as an outline only.
    public var showsPanel = true { didSet { needsDisplay = true } }

    /// The tile was clicked (or Space pressed on it).
    public var onPick: (() -> Void)?

    private let nameLabel = SettingsLabel(role: .secondary)
    private static let padding: CGFloat = 10
    private static let nameHeight: CGFloat = 22

    /// A tile drawing `position`, named `title`, `width` points wide.
    public init(position: DockPosition, title: String, width: CGFloat) {
        self.position = position
        super.init(frame: .zero)
        wantsLayer = true
        nameLabel.stringValue = title
        nameLabel.font = .systemFont(ofSize: 12, weight: .medium)
        nameLabel.alignment = .center
        nameLabel.textColor = ThemedControls.palette.mutedText
        addSubviewsForAutoLayout(nameLabel)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: width),
            heightAnchor.constraint(equalToConstant: (width - Self.padding * 2) * 0.62 + Self.padding * 2 + Self.nameHeight),
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.padding),
        ])
        setAccessibilityElement(true)
        setAccessibilityRole(.radioButton)
        setAccessibilityLabel(title)
        setAccessibilityValue(0)
        focusRingType = .none  // until the keyboard brings focus
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: ThemedControls.paletteDidChange, object: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func themeChanged() {
        nameLabel.textColor = isPicked ? ThemedControls.palette.accent : ThemedControls.palette.mutedText
        needsDisplay = true
    }

    // MARK: - Drawing

    /// The drawing's window, above the name.
    var windowRect: NSRect {
        let inner = bounds.insetBy(dx: Self.padding, dy: Self.padding)
        return NSRect(x: inner.minX, y: inner.minY + Self.nameHeight, width: inner.width, height: inner.height - Self.nameHeight)
    }

    /// The panel's region inside ``windowRect``: beside or under the content, never under the sidebar.
    var panelRect: NSRect {
        let content = contentRect
        switch position {
        case .leading: return NSRect(x: content.minX, y: content.minY, width: content.width * 0.38, height: content.height)
        case .trailing:
            return NSRect(x: content.maxX - content.width * 0.38, y: content.minY, width: content.width * 0.38, height: content.height)
        case .bottom: return NSRect(x: content.minX, y: content.minY, width: content.width, height: content.height * 0.42)
        }
    }

    /// Right of the rail and sidebar, under the title bar.
    private var contentRect: NSRect {
        let w = windowRect
        let side = w.width * 0.24
        return NSRect(x: w.minX + side, y: w.minY, width: w.width - side, height: w.height - Self.titleBar)
    }

    private static let titleBar: CGFloat = 12

    public override func draw(_ dirtyRect: NSRect) {
        let palette = ThemedControls.palette
        let card = NSBezierPath(
            roundedRect: bounds.insetBy(dx: ring.width / 2, dy: ring.width / 2), xRadius: SettingsMetrics.cardRadius,
            yRadius: SettingsMetrics.cardRadius)
        SettingsMetrics.cardFill.setFill()
        card.fill()

        let w = windowRect
        let window = NSBezierPath(roundedRect: w, xRadius: 5, yRadius: 5)
        palette.pageBackground.setFill()
        window.fill()
        NSGraphicsContext.saveGraphicsState()
        window.addClip()
        // Title bar with its three lights, and the sidebar.
        palette.sidebarBackground.setFill()
        NSRect(x: w.minX, y: w.maxY - Self.titleBar, width: w.width, height: Self.titleBar).fill()
        NSRect(x: w.minX, y: w.minY, width: contentRect.minX - w.minX, height: w.height).fill()
        palette.mutedText.withAlphaComponent(0.45).setFill()
        for i in 0..<3 {
            NSBezierPath(ovalIn: NSRect(x: w.minX + 5 + CGFloat(i) * 6, y: w.maxY - Self.titleBar / 2 - 2, width: 4, height: 4)).fill()
        }
        let sideX = w.minX + 6
        for (i, fraction) in [0.7, 0.5, 0.6, 0.45, 0.55].enumerated() {
            bar(x: sideX, y: w.maxY - Self.titleBar - 9 - CGFloat(i) * 7, width: (contentRect.minX - sideX - 6) * fraction, alpha: 0.3)
        }
        // The code, in the content the panel leaves.
        let panel = panelRect
        var code = contentRect
        switch position {
        case .leading: code = NSRect(x: panel.maxX, y: code.minY, width: code.maxX - panel.maxX, height: code.height)
        case .trailing: code = NSRect(x: code.minX, y: code.minY, width: panel.minX - code.minX, height: code.height)
        case .bottom: code = NSRect(x: code.minX, y: panel.maxY, width: code.width, height: code.maxY - panel.maxY)
        }
        var y = code.maxY - 8
        for (i, fraction) in [0.55, 0.8, 0.4, 0.7, 0.6, 0.35, 0.75].enumerated() where y > code.minY + 3 {
            let x = code.minX + 6 + (i % 3 == 1 ? 6 : 0)
            bar(x: x, y: y, width: (code.width - 18) * fraction, alpha: 0.28, accent: i % 3 == 0)
            y -= 7
        }
        // The panel: a prompt and its output.
        let inner = panel.insetBy(dx: 1, dy: 1)
        if showsPanel {
            palette.foreground.withAlphaComponent(palette.isDark ? 0.07 : 0.05).setFill()
            inner.fill()
        } else {
            let outline = NSBezierPath(rect: inner.insetBy(dx: 0.5, dy: 0.5))
            outline.setLineDash([3, 2], count: 2, phase: 0)
            palette.mutedText.withAlphaComponent(0.4).setStroke()
            outline.stroke()
        }
        palette.rowSeparator.setFill()
        switch position {
        case .leading: NSRect(x: panel.maxX - 1, y: panel.minY, width: 1, height: panel.height).fill()
        case .trailing: NSRect(x: panel.minX, y: panel.minY, width: 1, height: panel.height).fill()
        case .bottom: NSRect(x: panel.minX, y: panel.maxY - 1, width: panel.width, height: 1).fill()
        }
        if showsPanel {
            var py = panel.maxY - 8
            for (i, fraction) in [0.35, 0.6, 0.45].enumerated() where py > panel.minY + 3 {
                bar(x: panel.minX + 6, y: py, width: (panel.width - 14) * fraction, alpha: 0.3, accent: i == 0)
                py -= 7
            }
        }
        NSGraphicsContext.restoreGraphicsState()
        palette.rowSeparator.setStroke()
        window.lineWidth = SettingsMetrics.hairline
        window.stroke()

        let (color, width) = ring
        color.setStroke()
        card.lineWidth = width
        card.stroke()
    }

    /// One skeleton line, 3 pt tall.
    private func bar(x: CGFloat, y: CGFloat, width: CGFloat, alpha: CGFloat, accent: Bool = false) {
        let palette = ThemedControls.palette
        (accent ? palette.accent.withAlphaComponent(0.6) : palette.mutedText.withAlphaComponent(alpha)).setFill()
        NSBezierPath(roundedRect: NSRect(x: x, y: y, width: max(4, width), height: 3), xRadius: 1.5, yRadius: 1.5).fill()
    }

    /// The ring's colour and width: the accent at 2 pt while picked, a hairline otherwise.
    var ring: (color: NSColor, width: CGFloat) {
        isPicked ? (ThemedControls.palette.accent, 2) : (ThemedControls.palette.rowSeparator, SettingsMetrics.hairline)
    }

    // MARK: - Picking

    public override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self) }

    public override func mouseUp(with event: NSEvent) {
        guard bounds.contains(convert(event.locationInWindow, from: nil)) else { return }
        onPick?()
    }

    public override var acceptsFirstResponder: Bool { true }
    public override var canBecomeKeyView: Bool { true }

    public override func becomeFirstResponder() -> Bool {
        let became = super.becomeFirstResponder()
        if became { focusRingType = ChoiceCardView.isKeyboardFocus(NSApp?.currentEvent) ? .default : .none }
        return became
    }

    public override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned { focusRingType = .none }
        return resigned
    }

    public override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == " " { onPick?() } else { super.keyDown(with: event) }
    }

    public override func accessibilityPerformPress() -> Bool {
        onPick?()
        return true
    }

    public override func drawFocusRingMask() {
        NSBezierPath(roundedRect: bounds, xRadius: SettingsMetrics.cardRadius, yRadius: SettingsMetrics.cardRadius).fill()
    }

    public override var focusRingMaskBounds: NSRect { bounds }
}
