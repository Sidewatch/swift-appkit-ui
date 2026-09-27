//
//  ThemedSegmentBar.swift
//  ThemedControls
//
//  A themed replacement for `NSSegmentedControl`: a rounded bar of segments with the accent on
//  the selected one.
//
//  Created by David Sherlock on 9/3/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A themed replacement for `NSSegmentedControl`: a rounded bar of segments with the accent on
/// the selected one. The stock control's bezel, dividers and text stay system-coloured whatever
/// the tint. Same `selectedSegment` and `target`/`action` as the stock one, so a swap is a type change.
public final class ThemedSegmentBar: NSControl {
    private let labels: [String]
    private let symbols: [String?]
    /// Selected index; setting it repaints without firing the action.
    public var selectedSegment: Int = 0 { didSet { needsDisplay = true } }
    /// Momentary (e.g. a +/− pair under a list): no segment stays selected, every click fires the
    /// action, and `clickedSegment` says which — the stock control's `.momentary`.
    public var isMomentary = false { didSet { needsDisplay = true } }
    /// The segment of the last click or press; -1 before any.
    public private(set) var clickedSegment = -1
    /// Draw the symbols alone and keep the labels for VoiceOver (a +/− pair reads "Add", "Remove").
    public var symbolsOnly = false { didSet { invalidateIntrinsicContentSize(); needsDisplay = true } }
    private var disabledSegments: Set<Int> = []
    /// A segment that draws dimmed and ignores clicks, keys and VoiceOver presses.
    public func setEnabled(_ enabled: Bool, forSegment i: Int) {
        if enabled { disabledSegments.remove(i) } else { disabledSegments.insert(i) }
        needsDisplay = true
    }
    /// Whether segment `i` accepts clicks (see ``setEnabled(_:forSegment:)``).
    public func isEnabled(forSegment i: Int) -> Bool { !disabledSegments.contains(i) }
    public override var isEnabled: Bool { didSet { needsDisplay = true } }
    /// Equal-width segments across the whole width instead of each hugging its label.
    public var fillsWidth = false { didSet { invalidateIntrinsicContentSize(); needsDisplay = true } }
    /// The bar's intrinsic height in points.
    public var barHeight: CGFloat = 24 { didSet { invalidateIntrinsicContentSize() } }
    /// How many segments the bar has.
    public var segmentCount: Int { labels.count }

    /// Creates a bar of `labels`, each optionally led by the SF Symbol at the same index.
    public init(labels: [String], symbols: [String?] = []) {
        self.labels = labels
        self.symbols = symbols.count == labels.count ? symbols : labels.map { _ in nil }
        super.init(frame: .zero)
        wantsLayer = true
        // Redraw on every resize. A layer-backed view is otherwise free to STRETCH its last
        // bitmap during a live resize, squeezing the labels into each other.
        layerContentsRedrawPolicy = .duringViewResize
        translatesAutoresizingMaskIntoConstraints = false
        NotificationCenter.default.addObserver(self, selector: #selector(reTheme), name: ThemedControls.paletteDidChange, object: nil)
    }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }
    @objc private func reTheme() { needsDisplay = true }

    private var textFont: NSFont { .systemFont(ofSize: 11, weight: .medium) }

    private func naturalWidth(_ i: Int) -> CGFloat {
        if symbolsOnly { return 32 }
        let text = (labels[i] as NSString).size(withAttributes: [.font: textFont]).width
        return ceil(text) + (symbols[i] == nil ? 0 : 18) + 24
    }

    public override var intrinsicContentSize: NSSize {
        let w = fillsWidth ? NSView.noIntrinsicMetric : labels.indices.reduce(CGFloat(0)) { $0 + naturalWidth($1) }
        return NSSize(width: w, height: barHeight)
    }

    /// Segment frames, left to right.
    public func frames() -> [NSRect] {
        guard !labels.isEmpty else { return [] }
        if fillsWidth {
            let w = bounds.width / CGFloat(labels.count)
            return labels.indices.map { NSRect(x: CGFloat($0) * w, y: 0, width: w, height: bounds.height) }
        }
        var x: CGFloat = 0
        return labels.indices.map { i in
            let w = naturalWidth(i); defer { x += w }
            return NSRect(x: x, y: 0, width: w, height: bounds.height)
        }
    }

    /// Text that reads on the accent: near-black on a light accent, white on a dark one.
    public static var onAccent: NSColor {
        let c = ThemedControls.palette.accent.usingColorSpace(.deviceRGB) ?? ThemedControls.palette.accent
        let lum = 0.299 * c.redComponent + 0.587 * c.greenComponent + 0.114 * c.blueComponent
        return lum > 0.62 ? NSColor.black.withAlphaComponent(0.85) : .white
    }

    public override func draw(_ dirtyRect: NSRect) {
        let outline = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 6, yRadius: 6)
        ThemedControls.palette.elevatedSurface(dark: 0.07, light: 0.04).setFill(); outline.fill()
        ThemedControls.palette.rowSeparator.setStroke(); outline.lineWidth = 1; outline.stroke()
        for (i, f) in frames().enumerated() {
            let selected = !isMomentary && i == selectedSegment
            if selected {
                let pill = NSBezierPath(roundedRect: f.insetBy(dx: 2, dy: 2), xRadius: 4, yRadius: 4)
                ThemedControls.palette.accent.withAlphaComponent(0.92).setFill(); pill.fill()
            } else if i > 0, isMomentary || i - 1 != selectedSegment {
                ThemedControls.palette.rowSeparator.setFill()
                NSRect(x: f.minX, y: f.midY - 6, width: 1, height: 12).fill()
            }
            let dimmed = !isEnabled || !isEnabled(forSegment: i)
            let color = (selected ? Self.onAccent : ThemedControls.palette.foreground.withAlphaComponent(0.85)).withAlphaComponent(
                dimmed ? 0.35 : 1)
            let attrs: [NSAttributedString.Key: Any] = [.font: textFont, .foregroundColor: color]
            let plan = symbolsOnly ? (symbol: symbols[i], text: "") : content(for: i, width: f.width)
            let text = plan.text as NSString
            let ts = text.size(withAttributes: attrs)
            let symbolW: CGFloat = plan.symbol == nil ? 0 : (plan.text.isEmpty ? 14 : 18)
            let total = ts.width + symbolW
            var x = f.midX - total / 2
            if let name = plan.symbol, let img = NSImage.symbol(name, pointSize: 11, weight: .medium) {
                let tinted = img.tinted(color)
                tinted.draw(in: NSRect(x: x, y: f.midY - 7, width: 14, height: 14), from: .zero, operation: .sourceOver, fraction: 1)
                x += symbolW
            }
            text.draw(at: NSPoint(x: x, y: f.midY - ts.height / 2), withAttributes: attrs)
        }
    }

    /// What fits in a segment `width` wide: symbol and text, the symbol alone, or the text
    /// cut with an ellipsis — so a narrow sidebar shortens the labels instead of overlapping them.
    public func content(for i: Int, width: CGFloat) -> (symbol: String?, text: String) {
        let inner = width - 12
        let symbolW: CGFloat = symbols[i] == nil ? 0 : 18
        if textWidth(labels[i]) + symbolW <= inner { return (symbols[i], labels[i]) }
        if symbols[i] != nil, inner >= 14 { return (symbols[i], "") }
        var text = labels[i]
        while !text.isEmpty, textWidth(text + "…") > inner { text.removeLast() }
        return (nil, text.isEmpty ? "" : text + "…")
    }

    private func textWidth(_ text: String) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: textFont]).width)
    }

    public override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }
        let p = convert(event.locationInWindow, from: nil)
        guard let i = frames().firstIndex(where: { $0.contains(p) }) else { return }
        select(i)
    }

    /// Selects segment `i` and fires the action — what a click, an arrow key and VoiceOver do.
    /// Selecting the current segment is a no-op; a momentary bar fires on every press and
    /// keeps no selection. A disabled segment, or a disabled bar, does nothing.
    public func select(_ i: Int) {
        guard isEnabled, labels.indices.contains(i), isEnabled(forSegment: i) else { return }
        if isMomentary {
            clickedSegment = i
            if let action { sendAction(action, to: target) }
            return
        }
        guard i != selectedSegment else { return }
        clickedSegment = i
        selectedSegment = i
        if let action { sendAction(action, to: target) }
    }

    // MARK: Keyboard — Full Keyboard Access lands here and ← → move the selection.

    public override var acceptsFirstResponder: Bool { isEnabled }
    public override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123: select(max(0, selectedSegment - 1))  // ←
        case 124: select(min(labels.count - 1, selectedSegment + 1))  // →
        default: super.keyDown(with: event)
        }
    }
    public override func drawFocusRingMask() { NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6).fill() }
    public override var focusRingMaskBounds: NSRect { bounds }

    // MARK: Accessibility — a radio group whose children are the segments.

    private lazy var segmentElements: [SegmentElement] = labels.indices.map { i in
        let element = SegmentElement()
        element.setAccessibilityRole(.radioButton)
        element.setAccessibilityLabel(labels[i])
        element.setAccessibilityParent(self)
        nonisolated(unsafe) weak var me: ThemedSegmentBar? = self
        element.onPress = { MainActor.assumeIsolated { me?.select(i) } }
        return element
    }

    public override func isAccessibilityElement() -> Bool { true }
    public override func accessibilityRole() -> NSAccessibility.Role? { .radioGroup }
    public override func accessibilityValue() -> Any? { labels.indices.contains(selectedSegment) ? labels[selectedSegment] : nil }
    public override func accessibilityChildren() -> [Any]? {
        let rects = frames()
        for (i, element) in segmentElements.enumerated() {
            element.setAccessibilityValue(i == selectedSegment ? 1 : 0)
            if i < rects.count { element.setAccessibilityFrameInParentSpace(rects[i]) }
        }
        return segmentElements
    }
}

/// One segment as VoiceOver sees it: a radio button that presses back into the bar. Not
/// main-actor (AppKit's accessibility classes are not); the press hops explicitly.
nonisolated private final class SegmentElement: NSAccessibilityElement {
    nonisolated(unsafe) var onPress: (@Sendable () -> Void)?
    override func accessibilityPerformPress() -> Bool { onPress?(); return true }
}
