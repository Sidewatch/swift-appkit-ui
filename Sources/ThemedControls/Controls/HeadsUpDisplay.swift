//
//  HeadsUpDisplay.swift
//  ThemedControls
//
//  A brief capsule at the top of a window confirming what just happened — "Copied SHA-256" —
//  for an action nothing else on screen shows working.
//
//  Created by David Sherlock on 9/24/26.
//

import AppKit

/// A brief pill at the top centre of a window confirming what just happened — "Copied
/// SHA-256", "Copied 3 paths" — for actions where nothing else on screen changes to show they
/// worked. A capsule of window material with a soft shadow, an SF Symbol in the palette's
/// accent beside 13-pt text in its foreground, fading in over 0.12 s, staying 1.3 s, fading
/// out over 0.2 s. ONE per window, reused — a new show restarts the dwell; it takes no clicks
/// (`hitTest` → nil), sits in the window's content view above everything just under the title
/// strip (`contentLayoutRect`), and posts a VoiceOver announcement. `ThemedControls.reduceMotion`
/// drops the fades. Moved here from Sidewatch on 24 Sep 2026 (another app's heads-up display,
/// in AppKit).
public final class HeadsUpDisplay: NSView {
    /// How long the capsule stays before fading.
    public static let dwell: TimeInterval = 1.3
    private static let fadeIn: TimeInterval = 0.12, fadeOut: TimeInterval = 0.2
    private static let topInset: CGFloat = 12
    public let label = NSTextField(labelWithString: "")
    public let icon = NSImageView()
    private let material = NSVisualEffectView()
    private var hideWork: DispatchWorkItem?

    private init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.masksToBounds = false
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.18
        layer?.shadowRadius = 8
        layer?.shadowOffset = CGSize(width: 0, height: -3)
        material.material = .popover
        material.blendingMode = .withinWindow
        material.state = .active
        material.wantsLayer = true
        material.layer?.masksToBounds = true
        material.layer?.cornerCurve = .continuous
        addSubview(material)
        icon.symbolConfiguration = .init(pointSize: 13, weight: .semibold)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        addSubview(icon)
        addSubview(label)
        isHidden = true
        alphaValue = 0
        setAccessibilityElement(false)   // announced instead, see `present`
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    public override func hitTest(_ point: NSPoint) -> NSView? { nil }

    /// The window's display, made on first use.
    private static func display(in window: NSWindow) -> HeadsUpDisplay? {
        guard let content = window.contentView else { return nil }
        if let d = content.subviews.compactMap({ $0 as? HeadsUpDisplay }).first { return d }
        let d = HeadsUpDisplay()
        content.addSubview(d)
        return d
    }
    /// The window's display if it is on screen right now.
    public static func showing(in window: NSWindow) -> HeadsUpDisplay? {
        window.contentView?.subviews.compactMap { $0 as? HeadsUpDisplay }.first { !$0.isHidden }
    }

    /// `title` beside `systemImage`, at the top centre of `window`. A nil window shows nothing.
    public static func show(_ title: String, systemImage: String, in window: NSWindow?) {
        guard let window, let d = display(in: window) else { return }
        d.present(title: title, systemImage: systemImage)
    }

    private func present(title: String, systemImage: String) {
        guard let content = superview, let window else { return }
        hideWork?.cancel()
        let palette = ThemedControls.palette
        label.stringValue = title
        label.textColor = palette.foreground
        icon.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil)
        icon.contentTintColor = palette.accent
        label.sizeToFit()
        let padX: CGFloat = 14, padY: CGFloat = 9, gap: CGFloat = 8
        let iconSize = NSSize(width: 16, height: 16)
        let h = max(label.frame.height, iconSize.height) + padY * 2
        let w = padX + iconSize.width + gap + min(label.frame.width, 480) + padX
        material.frame = NSRect(origin: .zero, size: NSSize(width: w, height: h))
        material.layer?.cornerRadius = h / 2
        icon.frame = NSRect(x: padX, y: (h - iconSize.height) / 2, width: iconSize.width, height: iconSize.height)
        label.frame = NSRect(x: padX + iconSize.width + gap, y: (h - label.frame.height) / 2, width: min(label.frame.width, 480), height: label.frame.height)
        let layout = content.convert(window.contentLayoutRect, from: nil)
        frame = NSRect(x: (layout.midX - w / 2).rounded(), y: layout.maxY - Self.topInset - h, width: w, height: h)
        content.addSubview(self, positioned: .above, relativeTo: nil)
        isHidden = false
        if ThemedControls.reduceMotion { alphaValue = 1 } else {
            NSAnimationContext.runAnimationGroup { ctx in ctx.duration = Self.fadeIn; animator().alphaValue = 1 }
        }
        NSAccessibility.post(element: content, notification: .announcementRequested,
                             userInfo: [.announcement: title, .priority: NSAccessibilityPriorityLevel.medium.rawValue])
        let work = DispatchWorkItem { [weak self] in self?.dismiss() }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.dwell, execute: work)
    }

    private func dismiss() {
        if ThemedControls.reduceMotion { alphaValue = 0; isHidden = true; return }
        NSAnimationContext.runAnimationGroup({ ctx in ctx.duration = Self.fadeOut; animator().alphaValue = 0 },
                                            completionHandler: { [weak self] in
            MainActor.assumeIsolated { guard let self, self.alphaValue == 0 else { return }; self.isHidden = true }
        })
    }
}
