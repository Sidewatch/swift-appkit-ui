//
//  ThemedCheckbox.swift
//  ThemedControls
//
//  A theme-tinted checkbox.
//
//  Created by David Sherlock on 7/19/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A theme-tinted checkbox: the stock `.switch` button fills with the system accent, so this
/// draws its own rounded box (accent fill and a white check when on) and its title. Only drawing
/// is overridden; toggling, target/action and click tracking are a normal `.switch` button's.
open class ThemedCheckbox: NSButton {
    private let boxSize: CGFloat = 15
    private let gap: CGFloat = 6

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setButtonType(.switch)
        isBordered = false
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged),
                                               name: ThemedControls.paletteDidChange, object: nil)
    }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func themeChanged() { needsDisplay = true }

    /// Keep the accent crisp inside vibrant table rows / sidebars.
    open override var allowsVibrancy: Bool { false }

    open override var intrinsicContentSize: NSSize {
        let t = titleSize()
        return NSSize(width: t.width > 0 ? boxSize + gap + t.width : boxSize,
                      height: max(boxSize, t.height))
    }

    private func titleSize() -> NSSize {
        guard !title.isEmpty else { return .zero }
        return (title as NSString).size(withAttributes: [.font: font ?? .systemFont(ofSize: 12)])
    }

    open override func draw(_ dirtyRect: NSRect) {
        let box = NSRect(x: 0, y: (bounds.height - boxSize) / 2, width: boxSize, height: boxSize)
            .insetBy(dx: 0.5, dy: 0.5)
        let path = NSBezierPath(roundedRect: box, xRadius: 4, yRadius: 4)

        if state == .on {
            ThemedControls.palette.accent.setFill(); path.fill()
            // Checkmark points as fractions of the box, y measured from the VISUAL
            // bottom — resolved against `isFlipped` so the tick is never inverted
            // whichever way the view's coordinate system runs.
            func pt(_ fx: CGFloat, _ fyFromBottom: CGFloat) -> NSPoint {
                let x = box.minX + box.width * fx
                let y = isFlipped ? box.maxY - box.height * fyFromBottom
                                  : box.minY + box.height * fyFromBottom
                return NSPoint(x: x, y: y)
            }
            let check = NSBezierPath()
            check.lineWidth = 1.8; check.lineCapStyle = .round; check.lineJoinStyle = .round
            check.move(to: pt(0.26, 0.52))
            check.line(to: pt(0.43, 0.33))
            check.line(to: pt(0.75, 0.70))
            NSColor.white.setStroke(); check.stroke()
        } else {
            ThemedControls.palette.foreground.withAlphaComponent(ThemedControls.palette.isDark ? 0.10 : 0.05).setFill(); path.fill()
            path.lineWidth = 1; ThemedControls.palette.border.setStroke(); path.stroke()
        }

        if !title.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font ?? .systemFont(ofSize: 12),
                .foregroundColor: ThemedControls.palette.foreground,
            ]
            let ts = (title as NSString).size(withAttributes: attrs)
            (title as NSString).draw(at: NSPoint(x: boxSize + gap, y: (bounds.height - ts.height) / 2),
                                     withAttributes: attrs)
        }
    }
}
