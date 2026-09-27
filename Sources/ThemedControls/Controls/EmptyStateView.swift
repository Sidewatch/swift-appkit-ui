//
//  EmptyStateView.swift
//  ThemedControls
//
//  A centered icon + title + subtitle empty state, shared by the sidebar panels and lists.
//
//  Created by David Sherlock on 7/17/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A centred icon + title + subtitle empty state for panels and lists, explaining what will
/// appear and how to make it happen, with optional actions. Re-tints on `ThemedControls.paletteDidChange`.
public final class EmptyStateView: NSView {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(wrappingLabelWithString: "")
    private let button = NSButton(title: "", target: nil, action: nil)
    /// A secondary bordered action shown under the primary button (e.g. "Clone Repository").
    private let secondaryButton = NSButton(title: "", target: nil, action: nil)
    /// Invoked when the optional action button is clicked; nil hides the button.
    private var buttonAction: (() -> Void)?
    private var secondaryAction: (() -> Void)?
    /// The secondary button's title, re-applied by `applyTheme` on a palette change.
    private var secondaryTitleText: String?

    /// Creates a state showing the SF Symbol `symbol` above `title` and `subtitle`.
    public init(symbol: String, title: String, subtitle: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        iconView.translatesAutoresizingMaskIntoConstraints = false
        setSymbol(symbol)

        titleLabel.stringValue = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.stringValue = subtitle
        subtitleLabel.font = ThemedControls.palette.smallFont
        subtitleLabel.alignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // A FIXED wrap width is load-bearing: with the default (0 = automatic), the wrapping
        // label observes its own solved width and calls setNeedsUpdateConstraints on every
        // change — during a sidebar-divider drag that re-enters the layout pass until AppKit's
        // _postWindowNeedsUpdateConstraints throws (SIGABRT). A constant stops the observation.
        subtitleLabel.preferredMaxLayoutWidth = 220

        button.bezelStyle = .rounded
        button.controlSize = .small
        button.target = self
        button.action = #selector(buttonClicked)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false

        // A real bordered button, matching the primary. It was a borderless `.inline`
        // link, whose intrinsic width does not defend itself: the stack squeezed it to
        // "C…" and no amount of resizing helped, because the truncation was priority-driven
        // rather than space-driven. Compression resistance is set explicitly for the same
        // reason — the sibling subtitle lowers its own, so the default left this the most
        // squeezable view in the stack.
        secondaryButton.isBordered = true
        secondaryButton.bezelStyle = .rounded
        secondaryButton.controlSize = .small
        secondaryButton.font = ThemedControls.palette.smallFont
        secondaryButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        secondaryButton.target = self
        secondaryButton.action = #selector(secondaryClicked)
        secondaryButton.isHidden = true
        secondaryButton.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [iconView, titleLabel, subtitleLabel, button, secondaryButton])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 6
        stack.setCustomSpacing(12, after: iconView)
        stack.setCustomSpacing(14, after: subtitleLabel)
        stack.setCustomSpacing(8, after: button)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            subtitleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
        ])

        applyTheme()
        NotificationCenter.default.addObserver(
            self, selector: #selector(themeChanged), name: ThemedControls.paletteDidChange, object: nil)
    }

    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func buttonClicked() { buttonAction?() }
    @objc private func secondaryClicked() { secondaryAction?() }

    /// Sets (or clears) the optional call-to-action button under the copy. Pass nil
    /// for either argument to hide it.
    public func setButton(title: String?, action: (() -> Void)?) {
        if let title, let action {
            button.title = title
            button.isHidden = false
            buttonAction = action
        } else {
            button.isHidden = true
            buttonAction = nil
        }
    }

    /// Sets (or clears) the secondary link-style action shown beneath the primary button.
    public func setSecondaryButton(title: String?, action: (() -> Void)?) {
        secondaryTitleText = (action == nil) ? nil : title
        if let title, let action {
            applySecondaryTitle(title)
            secondaryButton.isHidden = false
            secondaryAction = action
        } else {
            secondaryButton.isHidden = true
            secondaryAction = nil
        }
    }

    /// Sets the secondary button's title, plain rather than accent-tinted: accent on a bezel
    /// reads as an error state.
    private func applySecondaryTitle(_ title: String) {
        secondaryButton.title = title
    }

    /// Swaps the explanatory copy (e.g. "no folder open" vs "no session").
    public func setText(title: String, subtitle: String) {
        titleLabel.stringValue = title
        subtitleLabel.stringValue = subtitle
    }

    /// Swaps the glyph — a list's "nothing here yet" and "your filter matched
    /// nothing" states are different situations and shouldn't share an icon.
    public func setSymbol(_ symbol: String) {
        iconView.image = NSImage.symbol(symbol, pointSize: 34, weight: .light)
    }

    // MARK: - Hosting over a list

    /// Pins this state centered over `host` (a scroll view / table area) in `host`'s
    /// own superview, starting hidden. The host keeps its layout untouched — an
    /// empty state only ever covers it, so revealing one can't reflow the panel.
    public func install(over host: NSView) {
        guard let parent = host.superview else { return }
        isHidden = true
        parent.addSubview(self, positioned: .above, relativeTo: host)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 20),
            trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -20),
            centerYAnchor.constraint(equalTo: host.centerYAnchor),
        ])
    }

    /// Reveals the state with fresh copy, and (optionally) a call-to-action button.
    /// Omitting the button args clears any button a previous `show` set.
    public func show(symbol: String, title: String, subtitle: String,
              buttonTitle: String? = nil, action: (() -> Void)? = nil,
              secondaryTitle: String? = nil, secondaryAction: (() -> Void)? = nil) {
        setSymbol(symbol)
        setText(title: title, subtitle: subtitle)
        setButton(title: buttonTitle, action: action)
        setSecondaryButton(title: secondaryTitle, action: secondaryAction)
        isHidden = false
    }

    /// Hides the state (the list has rows again).
    public func hide() { isHidden = true }

    @objc private func themeChanged() { applyTheme() }

    private func applyTheme() {
        iconView.contentTintColor = ThemedControls.palette.statusText.withAlphaComponent(0.55)
        titleLabel.textColor = ThemedControls.palette.foreground.withAlphaComponent(0.8)
        subtitleLabel.textColor = ThemedControls.palette.statusText
        if let title = secondaryTitleText { applySecondaryTitle(title) }
    }
}
