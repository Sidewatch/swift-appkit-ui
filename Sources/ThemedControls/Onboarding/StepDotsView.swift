//
//  StepDotsView.swift
//  ThemedControls
//
//  A row of dots, one per step of a guide, the current one in the accent.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// The guide's progress as dots: one per step, the current one drawn long in the palette's accent,
/// the rest round in its muted text tone. VoiceOver reads the label the guide gives it ("Step 2
/// of 4").
final class StepDotsView: NSView {
    /// How many dots.
    var count = 0 { didSet { invalidateIntrinsicContentSize(); needsDisplay = true } }
    /// The dot drawn in the accent, from 0.
    var current = 0 { didSet { needsDisplay = true } }

    private static let diameter: CGFloat = 7
    private static let currentLength: CGFloat = 20
    private static let gap: CGFloat = 6

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
        NotificationCenter.default.addObserver(self, selector: #selector(repaint), name: ThemedControls.paletteDidChange, object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func repaint() { needsDisplay = true }

    override var intrinsicContentSize: NSSize {
        let width = count == 0 ? 0 : CGFloat(count - 1) * Self.diameter + Self.currentLength + CGFloat(count - 1) * Self.gap
        return NSSize(width: width, height: Self.diameter)
    }

    /// The colour dot `index` is drawn in.
    func color(of index: Int) -> NSColor {
        index == current ? ThemedControls.palette.accent : ThemedControls.palette.mutedText.withAlphaComponent(0.45)
    }

    override func draw(_ dirtyRect: NSRect) {
        let y = (bounds.height - Self.diameter) / 2
        var x: CGFloat = 0
        for index in 0..<count {
            color(of: index).setFill()
            let width = index == current ? Self.currentLength : Self.diameter
            let r = Self.diameter / 2
            NSBezierPath(roundedRect: NSRect(x: x, y: y, width: width, height: Self.diameter), xRadius: r, yRadius: r).fill()
            x += width + Self.gap
        }
    }
}
