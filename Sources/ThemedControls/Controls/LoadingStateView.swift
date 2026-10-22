//
//  LoadingStateView.swift
//  ThemedControls
//
//  A small spinner and caption for a surface whose first read is still running.
//
//  Created by David Sherlock on 10/22/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A small spinner over a caption ("Loading changes…") for a surface whose first read is still
/// running, so it never sits blank or shows an empty state that is not true yet. It appears only
/// once a load has run for ``delay``: a fast load ends before then and nothing flashes.
/// Re-tints on `ThemedControls.paletteDidChange`.
public final class LoadingStateView: NSView {
    /// How long a load runs before the state shows: long enough that a fast read never flashes
    /// it, short enough that a slow one is never a blank.
    public static let defaultDelay: TimeInterval = 0.25

    /// The wait before showing, for this view.
    public var delay: TimeInterval = LoadingStateView.defaultDelay

    /// Whether a load has begun and not yet ended (shown or still waiting out ``delay``).
    public private(set) var isLoading = false

    private let spinner = NSProgressIndicator()
    private let captionLabel = NSTextField(labelWithString: "")
    private let stack = NSStackView()
    private var pendingShow: DispatchWorkItem?

    /// Creates a hidden state with `caption` under the spinner.
    public init(caption: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isHidden = true

        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false
        captionLabel.stringValue = caption
        captionLabel.font = ThemedControls.palette.smallFont
        captionLabel.alignment = .center

        for view in [spinner, captionLabel] { stack.addArrangedSubview(view) }
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        applyTheme()
        NotificationCenter.default.addObserver(
            self, selector: #selector(themeChanged), name: ThemedControls.paletteDidChange, object: nil)
    }

    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    /// Pins this state centred over `host` (a scroll view or table area) in `host`'s own
    /// superview, starting hidden, as ``EmptyStateView/install(over:)`` does.
    public func install(over host: NSView) { coverCentred(over: host) }

    /// The caption under the spinner.
    public var caption: String {
        get { captionLabel.stringValue }
        set { captionLabel.stringValue = newValue }
    }

    /// A load began: the state shows once it has run for ``delay``, unless ``end()`` comes first.
    /// Calling it again while loading changes nothing (the first wait stands).
    public func begin() {
        guard !isLoading else { return }
        isLoading = true
        let show = DispatchWorkItem { [weak self] in
            guard let self else { return }  // `end()` cancels this item, on the same main queue
            self.isHidden = false
            self.spinner.startAnimation(nil)
        }
        pendingShow = show
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: show)
    }

    /// The load ended (with something to show or nothing): hidden at once, and a pending show
    /// is cancelled.
    public func end() {
        isLoading = false
        pendingShow?.cancel()
        pendingShow = nil
        spinner.stopAnimation(nil)
        isHidden = true
    }

    @objc private func themeChanged() { applyTheme() }

    private func applyTheme() {
        captionLabel.textColor = ThemedControls.palette.statusText
    }
}
