//
//  ThemedPopUpButton.swift
//  ThemedControls
//
//  An `NSPopUpButton` that keeps the native MENU and loses the system bezel: a rounded themed
//  box, the selected title (and its image) in the foreground colour, a quiet chevron.
//
//  Created by David Sherlock on 9/3/26.
//

import AppKit
import AppKitViews

/// An `NSPopUpButton` that keeps the native MENU and loses the system bezel: a rounded
/// themed box, the selected title (and its image) in the foreground colour, a quiet
/// chevron. The stock control on a dark warm palette drew a system-grey lozenge with a
/// blue chevron (Library's category filter, every Settings popup). Only drawing changes
/// — items, selection, target/action and the pop-up itself are the superclass's.
/// Not `final`: subclasses add their own menu on top.
open class ThemedPopUpButton: NSPopUpButton {
    public convenience init() { self.init(frame: .zero, pullsDown: false) }
    public override init(frame: NSRect, pullsDown: Bool) {
        super.init(frame: frame, pullsDown: pullsDown)
        setup()
    }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    private func setup() {
        isBordered = false
        font = .systemFont(ofSize: 12)
        wantsLayer = true
        NotificationCenter.default.addObserver(self, selector: #selector(reTheme), name: ThemedControls.paletteDidChange, object: nil)
    }
    @objc private func reTheme() { needsDisplay = true }

    open override var intrinsicContentSize: NSSize {
        let s = super.intrinsicContentSize
        return NSSize(width: max(60, s.width + 10), height: 22)
    }

    open override func draw(_ dirtyRect: NSRect) {
        let box = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 5, yRadius: 5)
        ThemedControls.palette.elevatedSurface(dark: 0.07, light: 0.04).setFill(); box.fill()
        ThemedControls.palette.rowSeparator.setStroke(); box.lineWidth = 1; box.stroke()
        let f = font ?? .systemFont(ofSize: 12)
        var x: CGFloat = 8
        if let img = selectedItem?.image {
            img.tinted(ThemedControls.palette.foreground).draw(in: NSRect(x: x, y: bounds.midY - 7, width: 14, height: 14),
                                              from: .zero, operation: .sourceOver, fraction: 1)
            x += 18
        }
        let para = NSMutableParagraphStyle(); para.lineBreakMode = .byTruncatingTail
        let attrs: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: ThemedControls.palette.foreground, .paragraphStyle: para]
        let title = (titleOfSelectedItem ?? "") as NSString
        let h = title.size(withAttributes: attrs).height
        title.draw(in: NSRect(x: x, y: bounds.midY - h / 2, width: max(0, bounds.width - x - 22), height: h), withAttributes: attrs)
        if let chevron = NSImage(systemSymbolName: "chevron.up.chevron.down", accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 8, weight: .semibold)) {
            chevron.tinted(ThemedControls.palette.mutedText).draw(in: NSRect(x: bounds.maxX - 16, y: bounds.midY - 5, width: 10, height: 10),
                                               from: .zero, operation: .sourceOver, fraction: 1)
        }
    }
}
