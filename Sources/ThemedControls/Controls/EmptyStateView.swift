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
    /// The secondary bordered actions shown under the primary button, in order (e.g. "New
    /// Project", "Clone Repository"). Built on demand; the unused ones are hidden.
    private var secondaryButtons: [NSButton] = []
    private let stack = NSStackView()
    /// Invoked when the optional action button is clicked; nil hides the button.
    private var buttonAction: (() -> Void)?
    /// One handler per visible secondary button, by position.
    private var secondaryActions: [() -> Void] = []

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

        for view in [iconView, titleLabel, subtitleLabel, button] { stack.addArrangedSubview(view) }
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
    @objc private func secondaryClicked(_ sender: NSButton) {
        guard let index = secondaryButtons.firstIndex(of: sender), secondaryActions.indices.contains(index) else { return }
        secondaryActions[index]()
    }

    /// A secondary action's button: a real bordered button, matching the primary. A borderless
    /// `.inline` link's intrinsic width does not defend itself — the stack squeezed it to "C…",
    /// because the truncation was priority-driven rather than space-driven. Compression
    /// resistance is set explicitly for the same reason: the sibling subtitle lowers its own, so
    /// the default left this the most squeezable view in the stack.
    private func makeSecondaryButton() -> NSButton {
        let b = NSButton(title: "", target: self, action: #selector(secondaryClicked(_:)))
        b.isBordered = true
        b.bezelStyle = .rounded
        b.controlSize = .small
        b.font = ThemedControls.palette.smallFont
        b.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        b.isHidden = true
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

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

    /// Sets (or clears) the one secondary action shown beneath the primary button.
    public func setSecondaryButton(title: String?, action: (() -> Void)?) {
        if let title, let action { setSecondaryButtons([(title, action)]) } else { setSecondaryButtons([]) }
    }

    /// Sets the secondary actions shown beneath the primary button, top to bottom; an empty list
    /// hides them all. Titles stay plain rather than accent-tinted: accent on a bezel reads as an
    /// error state.
    public func setSecondaryButtons(_ actions: [(title: String, action: () -> Void)]) {
        while secondaryButtons.count < actions.count {
            let b = makeSecondaryButton()
            let previous: NSView = secondaryButtons.last ?? button
            stack.setCustomSpacing(8, after: previous)
            stack.addArrangedSubview(b)
            secondaryButtons.append(b)
        }
        for (index, b) in secondaryButtons.enumerated() {
            b.isHidden = index >= actions.count
            if index < actions.count { b.title = actions[index].title }
        }
        secondaryActions = actions.map(\.action)
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
    public func show(
        symbol: String, title: String, subtitle: String,
        buttonTitle: String? = nil, action: (() -> Void)? = nil,
        secondaryTitle: String? = nil, secondaryAction: (() -> Void)? = nil
    ) {
        var secondary: [(title: String, action: () -> Void)] = []
        if let secondaryTitle, let secondaryAction { secondary.append((secondaryTitle, secondaryAction)) }
        show(symbol: symbol, title: title, subtitle: subtitle, buttonTitle: buttonTitle, action: action, secondary: secondary)
    }

    /// Reveals the state with fresh copy, an optional call-to-action button, and the secondary
    /// actions beneath it, top to bottom.
    public func show(
        symbol: String, title: String, subtitle: String,
        buttonTitle: String?, action: (() -> Void)?,
        secondary: [(title: String, action: () -> Void)]
    ) {
        setSymbol(symbol)
        setText(title: title, subtitle: subtitle)
        setButton(title: buttonTitle, action: action)
        setSecondaryButtons(secondary)
        isHidden = false
    }

    /// Hides the state (the list has rows again).
    public func hide() { isHidden = true }

    @objc private func themeChanged() { applyTheme() }

    private func applyTheme() {
        iconView.contentTintColor = ThemedControls.palette.statusText.withAlphaComponent(0.55)
        titleLabel.textColor = ThemedControls.palette.foreground.withAlphaComponent(0.8)
        subtitleLabel.textColor = ThemedControls.palette.statusText
    }
}
