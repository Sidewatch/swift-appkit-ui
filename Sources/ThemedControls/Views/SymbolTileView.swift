//
//  SymbolTileView.swift
//  ThemedControls
//
//  An SF Symbol on a small rounded tile tinted with the accent — a settings row's mark.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// An SF Symbol centred on a rounded square in the palette's accent at low strength, the symbol
/// in the full accent: the mark System Settings puts before a row, drawn from the palette so it
/// follows the theme. Decoration — the row's caption names it — so hidden from accessibility.
final class SymbolTileView: NSView {
    /// The tile's side, in points.
    static let side: CGFloat = 24

    private let imageView = NSImageView()

    init(symbol: String, side: CGFloat = SymbolTileView.side) {
        super.init(frame: .zero)
        imageView.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        imageView.symbolConfiguration = .init(pointSize: side * 0.55, weight: .medium)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: side),
            heightAnchor.constraint(equalToConstant: side),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        setAccessibilityElement(false)
        applyTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: ThemedControls.paletteDidChange, object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { NotificationCenter.default.removeObserver(self) }

    /// Whether the symbol name resolved to an image.
    var hasSymbol: Bool { imageView.image != nil }

    @objc private func applyTheme() {
        imageView.contentTintColor = ThemedControls.palette.accent
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        ThemedControls.palette.accent.withAlphaComponent(ThemedControls.palette.isDark ? 0.18 : 0.13).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: bounds.width * 0.26, yRadius: bounds.width * 0.26).fill()
    }
}
