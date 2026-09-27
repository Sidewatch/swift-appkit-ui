//
//  ThemedSwitch.swift
//  ThemedControls
//
//  A theme-tinted on/off switch: the palette accent when on, where NSSwitch shows the macOS accent.
//
//  Created by David Sherlock on 9/19/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A theme-tinted on/off switch: `NSSwitch` fills with the macOS accent and has no tint API.
/// Draws its track and knob from the palette (accent on, a lifted surface off), slides over
/// 0.18 s, toggles on click and Space, and reads to VoiceOver as a switch. Same `state`,
/// `target`/`action`, `isEnabled` and footprint as `NSSwitch`, so a swap is a type change.
open class ThemedSwitch: NSControl {
    /// `.on` or `.off`. Setting it repaints (sliding while on screen) without firing the action.
    public var state: NSControl.StateValue = .off {
        didSet { if state != oldValue { slide(to: state == .on ? 1 : 0, animated: window != nil && !ThemedControls.reduceMotion) } }
    }

    /// True while the knob is mid-slide (never under Reduce Motion, or off screen).
    public var isSliding: Bool { animation != nil }

    /// The stock switch's footprint, read once so the rows keep their geometry on every macOS.
    private static let footprint: NSSize = NSSwitch().intrinsicContentSize
    /// `.small` and `.mini` are the regular footprint scaled — `NSSwitch` reports ONE intrinsic
    /// size (54 × 24) whatever its `controlSize`, so there is nothing to read; the ratios are the
    /// HIG's small and mini against regular, rounded.
    private static func footprint(for size: NSControl.ControlSize) -> NSSize {
        let scale: CGFloat
        switch size {
        case .small: scale = 0.78
        case .mini: scale = 0.62
        default: return footprint
        }
        return NSSize(width: (footprint.width * scale).rounded(), height: (footprint.height * scale).rounded())
    }
    /// The size class follows the stock switch's: the footprint and the drawing scale with it.
    open override var controlSize: NSControl.ControlSize {
        didSet { invalidateIntrinsicContentSize(); needsDisplay = true }
    }
    /// 0 = knob at the left (off) … 1 = at the right (on); animated between the two.
    private var knobProgress: CGFloat = 0
    private var animation: SlideAnimation?

    public override init(frame: NSRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setAccessibilityRole(.checkBox)
        setAccessibilitySubrole(NSAccessibility.Subrole(rawValue: "AXSwitch"))
        NotificationCenter.default.addObserver(
            self, selector: #selector(themeChanged),
            name: ThemedControls.paletteDidChange, object: nil)
    }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func themeChanged() { needsDisplay = true }

    open override var intrinsicContentSize: NSSize { Self.footprint(for: controlSize) }

    /// The VISIBLE track of the stock switch (its rendered ink bounds): regular 32 × 21, small
    /// 26 × 17, mini 21 × 14, inside a 54 × 24 footprint. Must not paint the whole footprint —
    /// that stands two-thirds wider than the system's. The paint sits at the trailing end, 2 pt
    /// in and centred vertically, as the stock one does; layout and hit area keep the footprint.
    static func trackSize(for size: NSControl.ControlSize) -> NSSize {
        switch size {
        case .small: return NSSize(width: 26, height: 17)
        case .mini: return NSSize(width: 21, height: 14)
        default: return NSSize(width: 32, height: 21)
        }
    }
    /// Where the track is painted within `bounds`.
    var trackRect: NSRect {
        let size = Self.trackSize(for: controlSize)
        return NSRect(x: bounds.maxX - 2 - size.width, y: bounds.midY - size.height / 2, width: size.width, height: size.height)
    }
    open override var allowsVibrancy: Bool { false }
    open override var acceptsFirstResponder: Bool { isEnabled }
    open override var isEnabled: Bool { didSet { needsDisplay = true } }

    // MARK: Drawing

    open override func draw(_ dirtyRect: NSRect) {
        let r = trackRect
        let palette = ThemedControls.palette
        let on = palette.accent
        let off = palette.elevatedSurface(dark: 0.22, light: 0.14)
        let track = (on.blended(withFraction: 1 - knobProgress, of: off) ?? on)
            .withAlphaComponent(isEnabled ? 1 : 0.4)
        track.setFill()
        NSBezierPath(roundedRect: r, xRadius: r.height / 2, yRadius: r.height / 2).fill()

        let inset: CGFloat = 2
        let d = r.height - 2 * inset
        let x = r.minX + inset + (r.width - 2 * inset - d) * knobProgress
        let knob = NSRect(x: x, y: r.minY + inset, width: d, height: d)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 1.5
        shadow.shadowOffset = NSSize(width: 0, height: isFlipped ? 0.5 : -0.5)
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.set()
        NSColor.white.withAlphaComponent(isEnabled ? 1 : 0.7).setFill()
        NSBezierPath(ovalIn: knob).fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    open override func drawFocusRingMask() {
        let r = trackRect
        NSBezierPath(roundedRect: r, xRadius: r.height / 2, yRadius: r.height / 2).fill()
    }
    open override var focusRingMaskBounds: NSRect { bounds }

    // MARK: Interaction

    /// Flips the state and fires the action — what a click or Space does.
    public func toggle() {
        guard isEnabled else { return }
        state = state == .on ? .off : .on
        if let action { sendAction(action, to: target) }
    }

    open override func performClick(_ sender: Any?) { toggle() }

    open override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }
        // A button's contract: the toggle happens on a release INSIDE the control.
        var inside = true
        while let next = window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) {
            inside = bounds.contains(convert(next.locationInWindow, from: nil))
            if next.type == .leftMouseUp { break }
        }
        if inside { toggle() }
    }

    open override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == " " || event.keyCode == 36 { toggle() } else { super.keyDown(with: event) }
    }

    open override func isAccessibilityElement() -> Bool { true }
    open override func accessibilityValue() -> Any? { state == .on ? 1 : 0 }
    open override func accessibilityPerformPress() -> Bool { toggle(); return true }

    // MARK: Slide

    private func slide(to target: CGFloat, animated: Bool) {
        animation?.stop()
        animation = nil
        guard animated, abs(target - knobProgress) > 0.01 else {
            knobProgress = target
            needsDisplay = true
            return
        }
        let from = knobProgress
        let anim = SlideAnimation(duration: 0.18, animationCurve: .easeInOut)
        anim.animationBlockingMode = .nonblocking
        // The animation ticks on the main run loop (non-blocking mode) but is not itself
        // main-actor; the tick hops back explicitly, the house idiom for AppKit callbacks.
        nonisolated(unsafe) weak var me: ThemedSwitch? = self
        anim.onTick = { progress in
            MainActor.assumeIsolated {
                guard let me else { return }
                me.knobProgress = from + (target - from) * CGFloat(progress)
                me.needsDisplay = true
                if progress >= 1 { me.animation = nil }
            }
        }
        animation = anim
        anim.start()
    }
}

/// An `NSAnimation` that reports its progress to a closure — the run-loop-driven slide, no
/// display link and no Core Animation layer to keep in step with the switch's drawing.
nonisolated private final class SlideAnimation: NSAnimation {
    nonisolated(unsafe) var onTick: (@Sendable (Double) -> Void)?
    override var currentProgress: NSAnimation.Progress {
        didSet { onTick?(Double(currentProgress)) }
    }
}
