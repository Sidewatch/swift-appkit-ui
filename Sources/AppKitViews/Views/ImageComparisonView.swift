//
//  ImageComparisonView.swift
//  AppKitViews
//
//  Two versions of a picture: side by side, swiped, or the changed pixels marked.
//
//  Created by David Sherlock on 10/22/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// Two versions of a picture, shown one of three ways (``ImageComparisonMode``): side by side
/// with captions, both in one frame split by a divider the pointer drags (or ←/→ moves), or the
/// later version dimmed with the changed pixels drawn in a colour over it (`changeMask`: white
/// where a pixel changed, as swift-media-kit's ImageCompare makes it).
///
/// Each picture is fitted into its space with its shape kept and enlarged up to
/// ``ImageComparisonLayout/maxScale``, drawn without smoothing so pixels stay square, over a
/// checkerboard so clear pixels read as clear. Either side may be missing (an added or deleted
/// file): its pane is left empty with its caption. The host supplies the colours and the words.
public final class ImageComparisonView: NSView {
    /// How the versions are shown.
    public var mode: ImageComparisonMode = .sideBySide { didSet { needsDisplay = true; window?.invalidateCursorRects(for: self) } }
    /// The earlier version; nil for none.
    public var oldImage: CGImage? { didSet { needsDisplay = true } }
    /// The later version; nil for none.
    public var newImage: CGImage? { didSet { needsDisplay = true } }
    /// The changed pixels, white on black, the pictures' size; nil when none changed.
    public var changeMask: CGImage? { didSet { tintedChanges = nil; needsDisplay = true } }
    /// The captions under each side, side by side (and in the top corners while swiping).
    public var captions: (old: String, new: String) = ("", "") { didSet { needsDisplay = true } }
    /// The colours drawn with.
    public var colors: ImageComparisonColors { didSet { tintedChanges = nil; needsDisplay = true } }
    /// The swipe divider's place, 0…1 across the picture.
    public private(set) var swipePosition: CGFloat = 0.5
    /// Called when the pointer or a key moves the divider.
    public var onSwipe: ((CGFloat) -> Void)?

    /// The changed pixels in the change colour, made once per mask and colour.
    private var tintedChanges: CGImage?
    private static let gap: CGFloat = 16
    private static let inset: CGFloat = 12
    private static let captionHeight: CGFloat = 22
    private static let checker: CGFloat = 8

    public override var isFlipped: Bool { true }
    public override var acceptsFirstResponder: Bool { true }

    /// A view drawing in `colors`.
    public init(colors: ImageComparisonColors) {
        self.colors = colors
        super.init(frame: .zero)
    }

    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

    /// Moves the swipe divider to `position` (0…1).
    public func setSwipePosition(_ position: CGFloat) {
        swipePosition = min(1, max(0, position))
        needsDisplay = true
    }

    // MARK: - Geometry

    /// Where the swipe frame sits: the space the larger picture fits.
    var swipeFrame: CGRect {
        let area = bounds.insetBy(dx: Self.inset, dy: Self.inset)
        let sizes = [oldImage, newImage].compactMap { $0.map { CGSize(width: $0.width, height: $0.height) } }
        guard let largest = sizes.max(by: { $0.width * $0.height < $1.width * $1.height }) else { return .zero }
        return ImageComparisonLayout.fit(largest, in: area)
    }

    /// The side-by-side panes, the captions' strip taken off their bottoms.
    var sideBySidePanes: (old: CGRect, new: CGRect) {
        let area = bounds.insetBy(dx: Self.inset, dy: Self.inset)
        let panes = ImageComparisonLayout.panes(in: area, gap: Self.gap)
        func picture(_ pane: CGRect) -> CGRect {
            CGRect(x: pane.minX, y: pane.minY, width: pane.width, height: max(0, pane.height - Self.captionHeight))
        }
        return (picture(panes.old), picture(panes.new))
    }

    // MARK: - Drawing

    public override func draw(_ dirtyRect: NSRect) {
        colors.background.setFill()
        bounds.fill()
        switch mode {
        case .sideBySide: drawSideBySide()
        case .swipe: drawSwipe()
        case .changes: drawChanges()
        }
    }

    private func drawSideBySide() {
        let panes = sideBySidePanes
        for (image, pane, caption) in [(oldImage, panes.old, captions.old), (newImage, panes.new, captions.new)] {
            if let image { drawPicture(image, in: ImageComparisonLayout.fit(size(of: image), in: pane)) }
            drawCaption(caption, centredUnder: pane)
        }
    }

    private func drawSwipe() {
        let frame = swipeFrame
        guard frame.width > 0 else { return }
        let split = (frame.minX + frame.width * swipePosition).rounded()
        for (image, clip) in [
            (oldImage, CGRect(x: frame.minX, y: frame.minY, width: split - frame.minX, height: frame.height)),
            (newImage, CGRect(x: split, y: frame.minY, width: frame.maxX - split, height: frame.height)),
        ] {
            guard let image, clip.width > 0 else { continue }
            NSGraphicsContext.saveGraphicsState()
            clip.clip()
            drawPicture(image, in: ImageComparisonLayout.fit(size(of: image), in: frame))
            NSGraphicsContext.restoreGraphicsState()
        }
        colors.divider.setFill()
        NSRect(x: split - 1, y: frame.minY, width: 2, height: frame.height).fill()
        NSBezierPath(ovalIn: NSRect(x: split - 6, y: frame.midY - 6, width: 12, height: 12)).fill()
        drawCaption(captions.old, at: CGPoint(x: frame.minX + 6, y: frame.minY + 4))
        let newWidth = attributedCaption(captions.new).size().width
        drawCaption(captions.new, at: CGPoint(x: frame.maxX - 6 - newWidth, y: frame.minY + 4))
    }

    private func drawChanges() {
        guard let newImage else { return }
        let frame = ImageComparisonLayout.fit(size(of: newImage), in: bounds.insetBy(dx: Self.inset, dy: Self.inset))
        drawPicture(newImage, in: frame, opacity: 0.3)
        if let tinted = tintedChangeImage() { draw(tinted, in: frame) }
    }

    /// A picture over its checkerboard, without smoothing.
    private func drawPicture(_ image: CGImage, in rect: CGRect, opacity: CGFloat = 1) {
        guard rect.width > 0 else { return }
        drawChecker(in: rect)
        draw(image, in: rect, opacity: opacity)
    }

    private func draw(_ image: CGImage, in rect: CGRect, opacity: CGFloat = 1) {
        NSImage(cgImage: image, size: size(of: image)).draw(
            in: rect, from: .zero, operation: .sourceOver, fraction: opacity, respectFlipped: true,
            hints: [.interpolation: NSNumber(value: NSImageInterpolation.none.rawValue)])
    }

    private func drawChecker(in rect: CGRect) {
        colors.checkerLight.setFill()
        rect.fill()
        colors.checkerDark.setFill()
        let side = Self.checker
        var y = rect.minY, row = 0
        while y < rect.maxY {
            var x = rect.minX + (row % 2 == 0 ? 0 : side)
            while x < rect.maxX {
                NSRect(x: x, y: y, width: min(side, rect.maxX - x), height: min(side, rect.maxY - y)).fill()
                x += side * 2
            }
            y += side
            row += 1
        }
    }

    /// The mask's white pixels in the change colour, transparent elsewhere.
    private func tintedChangeImage() -> CGImage? {
        if let tintedChanges { return tintedChanges }
        guard let mask = changeMask,
            let context = CGContext(
                data: nil, width: mask.width, height: mask.height, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        let all = CGRect(x: 0, y: 0, width: mask.width, height: mask.height)
        context.clip(to: all, mask: mask)
        context.setFillColor((colors.change.usingColorSpace(.sRGB) ?? colors.change).cgColor)
        context.fill(all)
        tintedChanges = context.makeImage()
        return tintedChanges
    }

    private func attributedCaption(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: colors.caption])
    }

    private func drawCaption(_ text: String, centredUnder pane: CGRect) {
        let caption = attributedCaption(text)
        let width = caption.size().width
        caption.draw(at: CGPoint(x: (pane.midX - width / 2).rounded(), y: pane.maxY + 5))
    }

    private func drawCaption(_ text: String, at point: CGPoint) { attributedCaption(text).draw(at: point) }

    private func size(of image: CGImage) -> CGSize { CGSize(width: image.width, height: image.height) }

    // MARK: - Swiping

    public override func resetCursorRects() {
        if mode == .swipe { addCursorRect(swipeFrame, cursor: .resizeLeftRight) }
    }

    public override func mouseDown(with event: NSEvent) {
        guard mode == .swipe else { return super.mouseDown(with: event) }
        window?.makeFirstResponder(self)
        swipe(to: event)
    }

    public override func mouseDragged(with event: NSEvent) {
        guard mode == .swipe else { return super.mouseDragged(with: event) }
        swipe(to: event)
    }

    private func swipe(to event: NSEvent) {
        let x = convert(event.locationInWindow, from: nil).x
        setSwipePosition(ImageComparisonLayout.swipeFraction(atX: x, in: swipeFrame))
        onSwipe?(swipePosition)
    }

    /// ←/→ move the swipe divider a twentieth of the way.
    public override func keyDown(with event: NSEvent) {
        guard mode == .swipe, let key = event.specialKey, key == .leftArrow || key == .rightArrow else { return super.keyDown(with: event) }
        setSwipePosition(swipePosition + (key == .leftArrow ? -0.05 : 0.05))
        onSwipe?(swipePosition)
    }
}
