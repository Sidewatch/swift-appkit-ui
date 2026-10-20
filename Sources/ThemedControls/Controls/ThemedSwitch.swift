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

    /// The stock switch's regular footprint, read once so the rows keep their geometry on every macOS.
    private static let footprint: NSSize = NSSwitch().intrinsicContentSize
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

    /// The track's size: the footprint, so a row lays out exactly what is drawn.
    open override var intrinsicContentSize: NSSize { Self.trackSize(for: controlSize) }

    /// The stock switch's track, measured from its rendering (macOS 26/27): regular 54 × 24, the
    /// whole of its footprint; small 44 × 20 and mini 36 × 17, which `NSSwitch` draws centred in
    /// that same 54 × 24 (it reports one intrinsic size whatever its `controlSize`).
    static func trackSize(for size: NSControl.ControlSize) -> NSSize {
        switch size {
        case .small: return NSSize(width: 44, height: 20)
        case .mini: return NSSize(width: 36, height: 17)
        default: return footprint
        }
    }
    /// The stock knob: a capsule, not a circle — regular 32 × 20, small 26 × 16, mini 21 × 13 —
    /// inset evenly from the track's ends and edges.
    static func knobSize(for size: NSControl.ControlSize) -> NSSize {
        switch size {
        case .small: return NSSize(width: 26, height: 16)
        case .mini: return NSSize(width: 21, height: 13)
        default: return NSSize(width: 32, height: 20)
        }
    }
    /// Where the track is painted: centred in `bounds`, so a frame larger than the footprint
    /// (a stretched cell) keeps the stock size rather than a stretched pill.
    var trackRect: NSRect {
        let size = Self.trackSize(for: controlSize)
        return NSRect(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2, width: size.width, height: size.height)
    }
    /// Where the knob is painted: at the track's leading end when off, the trailing end when on.
    var knobRect: NSRect {
        let track = trackRect
        let size = Self.knobSize(for: controlSize)
        let inset = (track.height - size.height) / 2
        let x = track.minX + inset + (track.width - 2 * inset - size.width) * knobProgress
        return NSRect(x: x, y: track.minY + inset, width: size.width, height: size.height)
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

        let knob = knobRect
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 1.5
        shadow.shadowOffset = NSSize(width: 0, height: isFlipped ? 0.5 : -0.5)
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.set()
        NSColor.white.withAlphaComponent(isEnabled ? 1 : 0.7).setFill()
        NSBezierPath(roundedRect: knob, xRadius: knob.height / 2, yRadius: knob.height / 2).fill()
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
        anim.onTick = { [weak self] progress in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.knobProgress = from + (target - from) * CGFloat(progress)
                self.needsDisplay = true
                if progress >= 1 { self.animation = nil }
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
