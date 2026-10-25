//
//  ThemedPopUpButton.swift
//  ThemedControls
//
//  An `NSPopUpButton` that keeps the native MENU and loses the system bezel: a rounded themed
//  box, the selected title (and its image) in the foreground colour, a quiet chevron.
//
//  Created by David Sherlock on 9/3/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// An `NSPopUpButton` that keeps the native MENU and loses the system bezel (a grey lozenge with
/// a blue chevron): a rounded themed box, the selected title and image in the foreground colour,
/// a quiet chevron. Only drawing changes; items, selection and target/action are the superclass's.
open class ThemedPopUpButton: NSPopUpButton {
    /// The box's fill: the card it sits on, lifted toward the text colour enough to read as a
    /// control without an outline (the stock pop-up's step above its surface).
    static var fill: NSColor {
        let palette = ThemedControls.palette
        return palette.cardBackground.blended(withFraction: palette.isDark ? 0.1 : 0.07, of: palette.foreground) ?? palette.cardBackground
    }

    /// Creates an unsized pop-up (not pull-down) for Auto Layout.
    public convenience init() { self.init(frame: .zero, pullsDown: false) }
    public override init(frame: NSRect, pullsDown: Bool) {
        super.init(frame: frame, pullsDown: pullsDown)
        setup()
    }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    private func setup() {
        isBordered = false
        font = .systemFont(ofSize: NSFont.systemFontSize)  // the stock pop-up's 13 pt
        wantsLayer = true
        NotificationCenter.default.addObserver(self, selector: #selector(reTheme), name: ThemedControls.paletteDidChange, object: nil)
    }
    @objc private func reTheme() { needsDisplay = true }

    /// The stock pop-up's height for its text: 24 pt at 13 pt, and a compact 20 pt for a caller's 11 pt.
    open override var intrinsicContentSize: NSSize {
        let f = font ?? .systemFont(ofSize: NSFont.systemFontSize)
        // The widest item, measured as `draw` lays it out: text inset, an item's image, the arrows.
        let widest =
            itemArray.map { item in
                (item.title as NSString).size(withAttributes: [.font: f]).width + (item.image == nil ? 0 : 18)
            }.max() ?? 0
        return NSSize(width: max(60, ceil(widest) + Self.textInset + Self.arrowSpace(for: f)), height: Self.height(for: f))
    }

    private static let textInset: CGFloat = 10
    /// Room the arrows take after the text: their side, the trailing inset and a gap.
    private static func arrowSpace(for font: NSFont) -> CGFloat { arrowSide(for: font) + 8 + 8 }
    private static func arrowSide(for font: NSFont) -> CGFloat { (font.pointSize * 0.85).rounded() }  // 11 pt beside 13 pt

    static func height(for font: NSFont) -> CGFloat { (font.pointSize * 1.85).rounded() }

    open override func draw(_ dirtyRect: NSRect) {
        // The stock macOS 26 pop-up: a solid rounded fill with no outline, in the theme's surface.
        let box = NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6)
        Self.fill.setFill()
        box.fill()
        let f = font ?? .systemFont(ofSize: NSFont.systemFontSize)
        var x = Self.textInset
        if let img = selectedItem?.image {
            img.tinted(ThemedControls.palette.foreground).draw(
                in: NSRect(x: x, y: bounds.midY - 7, width: 14, height: 14),
                from: .zero, operation: .sourceOver, fraction: 1)
            x += 18
        }
        let para = NSMutableParagraphStyle(); para.lineBreakMode = .byTruncatingTail
        let attrs: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: ThemedControls.palette.foreground, .paragraphStyle: para]
        let title = (titleOfSelectedItem ?? "") as NSString
        let h = title.size(withAttributes: attrs).height
        title.draw(
            in: NSRect(x: x, y: bounds.midY - h / 2, width: max(0, bounds.width - x - Self.arrowSpace(for: f)), height: h),
            withAttributes: attrs)
        let side = Self.arrowSide(for: f)
        if let chevron = NSImage.symbol("chevron.up.chevron.down", pointSize: side - 2, weight: .bold) {
            chevron.tinted(ThemedControls.palette.foreground.withAlphaComponent(0.8)).draw(
                in: NSRect(x: bounds.maxX - side - 8, y: bounds.midY - side / 2, width: side, height: side),
                from: .zero, operation: .sourceOver, fraction: 1)
        }
    }
}
