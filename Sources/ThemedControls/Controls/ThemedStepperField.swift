//
//  ThemedStepperField.swift
//  ThemedControls
//
//  A number with up and down arrows, in the themed pop-up's box: the same height, fill and arrow
//  column, so a number row lines up with the pop-up rows around it.
//
//  Created by David Sherlock on 10/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A number field with a stepper, drawn as one control in `ThemedPopUpButton`'s box: 24 pt tall at
/// its 13 pt text, the pop-up's fill and radius, the number right-aligned and grouped ("10,000"),
/// and an up and a down arrow where the pop-up has its chevron. The stock `NSStepper` beside a
/// field is a separate, smaller system control in the system's grey.
///
/// The top half of the arrow column steps up and the bottom half down, repeating while held; ↑ and
/// ↓ step while typing. Typed text commits on Return or when the field loses focus: a number (with
/// or without grouping) is clamped to the range, anything else puts the last value back. Every
/// change of value, stepped or typed, sends `action` to `target`; setting `doubleValue` does not.
public final class ThemedStepperField: NSView, NSTextFieldDelegate {
    /// The least value a step or a typed number can reach.
    public var minValue: Double = 0 { didSet { setValue(value, notify: false) } }
    /// The greatest value; also what the width is measured for.
    public var maxValue: Double = 100 {
        didSet {
            setValue(value, notify: false)
            invalidateIntrinsicContentSize()
        }
    }
    /// How far one step moves the value.
    public var increment: Double = 1
    /// Receives `action` when the person changes the value.
    public weak var target: AnyObject?
    /// Sent to `target` on every change of value the person makes.
    public var action: Selector?

    /// The number's display and parsing: decimal, grouped, whole numbers by default.
    public let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        f.maximumFractionDigits = 0
        f.isLenient = true
        return f
    }()

    /// The value shown. Setting it clamps to the range and sends no action.
    public var doubleValue: Double {
        get { value }
        set { setValue(newValue, notify: false) }
    }
    /// The value as a whole number.
    public var integerValue: Int {
        get { Int(value.rounded()) }
        set { doubleValue = Double(newValue) }
    }

    private var value: Double = 0
    private let field = NSTextField()
    /// The arrow being held: +1 up, -1 down, 0 none.
    private var pressed = 0
    private var widthForValues: NSLayoutConstraint?

    /// Creates an unsized field for Auto Layout.
    public convenience init() { self.init(frame: .zero) }
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        let cell = PaddedFieldCell()
        cell.isEditable = true
        cell.isSelectable = true
        cell.isScrollable = true
        cell.usesSingleLineMode = true
        cell.sendsActionOnEndEditing = true
        field.cell = cell
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.alignment = .right
        field.font = .monoDigits(NSFont.systemFontSize)
        field.target = self
        field.action = #selector(commitTyped)
        field.delegate = self
        field.disableSystemTextIntelligence()
        field.translatesAutoresizingMaskIntoConstraints = false
        // The box sets the height; the field's own line height would otherwise tie with it and win.
        field.setContentHuggingPriority(.defaultLow, for: .vertical)
        field.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: leadingAnchor),
            field.topAnchor.constraint(equalTo: topAnchor),
            field.bottomAnchor.constraint(equalTo: bottomAnchor),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.arrowColumnWidth(for: font)),
        ])
        setAccessibilityElement(true)
        setAccessibilityRole(.incrementor)
        NotificationCenter.default.addObserver(self, selector: #selector(reTheme), name: ThemedControls.paletteDidChange, object: nil)
        reTheme()
        showValue()
    }

    private var font: NSFont { field.font ?? .systemFont(ofSize: NSFont.systemFontSize) }

    @objc private func reTheme() {
        field.textColor = ThemedControls.palette.foreground
        // The caret and selection follow the theme's light or dark mode, not the system's.
        field.appearance = NSAppearance(named: ThemedControls.palette.isDark ? .darkAqua : .aqua)
        needsDisplay = true
    }

    // MARK: - Size

    /// The pop-up's height for the text, and room for the widest value (the maximum, grouped)
    /// beside the arrows.
    public override var intrinsicContentSize: NSSize {
        let widest = ((formatter.string(from: NSNumber(value: maxValue)) ?? "") as NSString).size(withAttributes: [.font: font]).width
        // The cell's 6 pt padding each side, and room for the caret.
        return NSSize(width: ceil(widest) + 12 + 4 + Self.arrowColumnWidth(for: font), height: ThemedPopUpButton.height(for: font))
    }

    /// The arrows' side: the pop-up chevron's.
    private static func arrowSide(for font: NSFont) -> CGFloat { (font.pointSize * 0.85).rounded() }
    /// The arrow column at the trailing edge: the arrows centred where the pop-up centres its
    /// chevron (8 pt in from the edge), with a gap before them.
    private static func arrowColumnWidth(for font: NSFont) -> CGFloat { arrowSide(for: font) + 8 + 6 }

    /// The arrow column, the part of the box that steps.
    private var arrowColumn: NSRect {
        let w = Self.arrowColumnWidth(for: font)
        return NSRect(x: bounds.maxX - w, y: 0, width: w, height: bounds.height)
    }

    // MARK: - Drawing

    public override func draw(_ dirtyRect: NSRect) {
        let palette = ThemedControls.palette
        ThemedPopUpButton.fill.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6).fill()
        let side = Self.arrowSide(for: font)
        let centreX = bounds.maxX - 8 - side / 2
        let glyph = (side * 0.55).rounded()
        for direction in [1, -1] {
            guard
                let arrow = NSImage.symbol(direction == 1 ? "chevron.up" : "chevron.down", pointSize: glyph, weight: .bold)
            else { continue }
            let atMax = direction == 1 ? value >= maxValue : value <= minValue
            let alpha: CGFloat = pressed == direction ? 1 : (atMax ? 0.3 : 0.8)
            let size = arrow.size
            // Stacked about the middle, a point apart, in a non-flipped view (up is +y).
            let y = direction == 1 ? bounds.midY + 1 : bounds.midY - 1 - size.height
            arrow.tinted(palette.foreground.withAlphaComponent(alpha)).draw(
                in: NSRect(x: (centreX - size.width / 2).rounded(), y: y.rounded(), width: size.width, height: size.height),
                from: .zero, operation: .sourceOver, fraction: 1)
        }
    }

    // MARK: - Stepping

    /// Which way a click at `point` steps: +1 in the arrow column's top half, -1 in its bottom
    /// half, nil outside it.
    func stepDirection(at point: NSPoint) -> Int? {
        guard arrowColumn.contains(point) else { return nil }
        return point.y >= bounds.midY ? 1 : -1
    }

    /// A press on the arrows steps once, then repeats while the button stays down over the same
    /// arrow; a press elsewhere goes to the field.
    public override func mouseDown(with event: NSEvent) {
        guard let direction = stepDirection(at: convert(event.locationInWindow, from: nil)), let window else {
            super.mouseDown(with: event)
            return
        }
        if field.currentEditor() != nil { commitTyped() }
        pressed = direction
        step(direction)
        NSEvent.startPeriodicEvents(afterDelay: 0.4, withPeriod: 0.075)
        defer {
            NSEvent.stopPeriodicEvents()
            pressed = 0
            needsDisplay = true
        }
        while let next = window.nextEvent(matching: [.leftMouseUp, .leftMouseDragged, .periodic]) {
            if next.type == .leftMouseUp { break }
            let over = stepDirection(at: convert(window.mouseLocationOutsideOfEventStream, from: nil))
            pressed = over == direction ? direction : 0
            if next.type == .periodic, over == direction { step(direction) }
            needsDisplay = true
        }
    }

    /// Moves the value one increment up (+1) or down (-1) and reports it when it changed.
    private func step(_ direction: Int) {
        setValue(value + Double(direction) * increment, notify: true)
    }

    /// ↑ and ↓ step while the field is being typed in.
    public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.moveUp(_:)):
            commitTyped()
            step(1)
        case #selector(NSResponder.moveDown(_:)):
            commitTyped()
            step(-1)
        default: return false
        }
        textView.string = field.stringValue
        return true
    }

    /// The typed text: a number is clamped and kept, anything else puts the last value back.
    @objc private func commitTyped() {
        let typed = (field.currentEditor()?.string ?? field.stringValue).trimmingCharacters(in: .whitespaces)
        guard let number = formatter.number(from: typed)?.doubleValue ?? Double(typed) else {
            showValue()
            return
        }
        setValue(number, notify: true)
    }

    /// Clamps `newValue` into the range, shows it, and sends the action when `notify` and the
    /// value moved.
    private func setValue(_ newValue: Double, notify: Bool) {
        let clamped = min(max(newValue, minValue), max(minValue, maxValue))
        let moved = clamped != value
        value = clamped
        showValue()
        needsDisplay = true
        if notify, moved, let action { NSApp.sendAction(action, to: target, from: self) }
    }

    private func showValue() {
        let text = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        field.stringValue = text
        field.currentEditor()?.string = text
    }

    // MARK: - Accessibility

    public override func accessibilityValue() -> Any? { field.stringValue }
    public override func accessibilityPerformIncrement() -> Bool {
        step(1)
        return true
    }
    public override func accessibilityPerformDecrement() -> Bool {
        step(-1)
        return true
    }

    // MARK: - Testing

    /// The text the field shows now.
    public var displayedTextForTesting: String { field.stringValue }
    /// Types `text` into the field and commits it as Return would.
    public func typeForTesting(_ text: String) {
        field.stringValue = text
        _ = field.sendAction(field.action, to: field.target)
    }
    /// The field the number is typed into.
    var fieldForTesting: NSTextField { field }
}
