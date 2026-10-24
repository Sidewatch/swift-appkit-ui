//
//  StepFlowView.swift
//  ThemedControls
//
//  A step-by-step guide: one page at a time under its heading, with Back, Skip and Continue.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A guide of ``StepFlowStep`` pages shown one at a time: the page's symbol on an accent tile
/// beside its heading and line, the page's view below, and a footer of `‹ Back`, a dot per step
/// (the current one drawn long), `Skip` and the accent `Continue` (`Done` on the last page).
/// Return continues; Escape skips.
///
/// Every page is optional by construction: a page's controls show the current settings, so
/// Continue without touching them keeps the defaults, and Skip keeps them for every page not yet
/// seen. The view owns no settings — the pages' controls write their own — and reports the end
/// through ``onFinish``. It is laid out for ``preferredSize``; a page fills ``pageWidth``.
public final class StepFlowView: NSView {

    /// The pages, in order.
    public let steps: [StepFlowStep]
    /// Where the guide stands.
    public private(set) var flow: StepFlow

    /// The guide ended: every page seen (`.completed`) or skipped (`.skipped`).
    public var onFinish: ((StepFlow.Ending) -> Void)?
    /// A page came on screen, with its index.
    public var onStepShown: ((Int) -> Void)?

    /// The size the guide is laid out for: its window's content size.
    public static let preferredSize = NSSize(width: 680, height: 640)
    /// The inset of the heading, the page and the footer from each side.
    public static let margin: CGFloat = 32
    /// The width a page is given: the view less a margin each side. Wrapping text in a page sets
    /// its `preferredMaxLayoutWidth` from this.
    public static var pageWidth: CGFloat { preferredSize.width - margin * 2 }

    private static let tileSide: CGFloat = 46

    /// The heading's leading edge: past the symbol's tile, or at the margin for a page without one.
    private var headingBesideTile: NSLayoutConstraint!
    private var headingAtMargin: NSLayoutConstraint!

    private let tileHost = NSView()
    private let titleLabel = SettingsLabel(role: .primary)
    private let subtitleLabel = SettingsLabel(role: .secondary, wrapping: true)
    private let pageHost = NSView()
    private let footerRule = SettingsSeparatorView()
    private let dots = StepDotsView()
    private let backButton = ThemedActionButton(
        title: String(localized: "Back", bundle: .module, comment: "Step-by-step guide: go to the previous page"), style: .plain,
        symbol: "chevron.left", placement: .leading)
    private let skipButton = ThemedActionButton(
        title: String(localized: "Skip", bundle: .module, comment: "Step-by-step guide: end it, keeping the defaults"), style: .plain)
    private let continueButton = ThemedActionButton(title: "", style: .primary)

    /// A guide over `steps` (at least one), showing the first.
    public init(steps: [StepFlowStep]) {
        precondition(!steps.isEmpty, "a guide needs a page")
        self.steps = steps
        flow = StepFlow(count: steps.count)
        super.init(frame: NSRect(origin: .zero, size: Self.preferredSize))
        build()
        show(0)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Moves

    /// Continue: the next page, or the end after the last.
    @objc public func goForward() { move { $0.advance() } }

    /// Back: the previous page.
    @objc public func goBack() { move { $0.back() } }

    /// Skip: the end, keeping the defaults of every page not yet seen.
    @objc public func skip() { move { $0.skip() } }

    /// Makes one move, then reports the end or shows the page it lands on. Once the guide has
    /// ended a move does nothing, so a late click or key never reports the end twice.
    private func move(_ change: (inout StepFlow) -> Void) {
        guard !flow.isFinished else { return }
        change(&flow)
        if let ending = flow.ending { onFinish?(ending) } else { show(flow.index) }
    }

    // MARK: - Layout

    private func build() {
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        subtitleLabel.font = .systemFont(ofSize: 13)
        let textWidth = Self.pageWidth - Self.tileSide - 16
        subtitleLabel.preferredMaxLayoutWidth = textWidth

        backButton.target = self
        backButton.action = #selector(goBack)
        skipButton.target = self
        skipButton.action = #selector(skip)
        skipButton.keyEquivalent = "\u{1b}"
        continueButton.target = self
        continueButton.action = #selector(goForward)
        continueButton.keyEquivalent = "\r"
        dots.count = steps.count

        let trailing = NSStackView(views: [skipButton, continueButton])
        trailing.orientation = .horizontal
        trailing.spacing = 10
        let heading = NSStackView(views: [titleLabel, subtitleLabel])
        heading.orientation = .vertical
        heading.alignment = .leading
        heading.spacing = 4

        addSubviewsForAutoLayout(tileHost, heading, pageHost, footerRule, backButton, dots, trailing)
        let m = Self.margin
        NSLayoutConstraint.activate([
            tileHost.topAnchor.constraint(equalTo: topAnchor, constant: 44),
            tileHost.leadingAnchor.constraint(equalTo: leadingAnchor, constant: m),
            tileHost.widthAnchor.constraint(equalToConstant: Self.tileSide),
            tileHost.heightAnchor.constraint(equalToConstant: Self.tileSide),
            heading.topAnchor.constraint(equalTo: tileHost.topAnchor, constant: -2),
            heading.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -m),
            subtitleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: textWidth),
            pageHost.topAnchor.constraint(greaterThanOrEqualTo: heading.bottomAnchor, constant: 22),
            pageHost.topAnchor.constraint(greaterThanOrEqualTo: tileHost.bottomAnchor, constant: 22),
            pageHost.leadingAnchor.constraint(equalTo: leadingAnchor, constant: m),
            pageHost.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -m),
            pageHost.bottomAnchor.constraint(equalTo: footerRule.topAnchor, constant: -16),
            footerRule.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerRule.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerRule.heightAnchor.constraint(equalToConstant: SettingsMetrics.hairline),
            footerRule.bottomAnchor.constraint(equalTo: trailing.topAnchor, constant: -16),
            trailing.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -m),
            trailing.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: m - 6),
            backButton.centerYAnchor.constraint(equalTo: trailing.centerYAnchor),
            dots.centerXAnchor.constraint(equalTo: centerXAnchor),
            dots.centerYAnchor.constraint(equalTo: trailing.centerYAnchor),
        ])
        headingBesideTile = heading.leadingAnchor.constraint(equalTo: tileHost.trailingAnchor, constant: 16)
        headingAtMargin = heading.leadingAnchor.constraint(equalTo: leadingAnchor, constant: m)
        // The page starts under whichever is taller, the tile or the heading, and no lower.
        let tight = pageHost.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 22)
        tight.priority = .defaultHigh
        tight.isActive = true
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        subtitleLabel.setContentHuggingPriority(.required, for: .vertical)
    }

    /// Puts page `index` on screen and names the footer's moves for it.
    private func show(_ index: Int) {
        let step = steps[index]
        titleLabel.stringValue = step.title
        subtitleLabel.stringValue = step.subtitle
        tileHost.subviews.forEach { $0.removeFromSuperview() }
        if let symbol = step.symbol {
            let tile = SymbolTileView(symbol: symbol, side: Self.tileSide)
            tileHost.addSubview(tile)
            tile.pinEdges(to: tileHost)
        }
        headingAtMargin.isActive = step.symbol == nil
        headingBesideTile.isActive = step.symbol != nil
        pageHost.subviews.forEach { $0.removeFromSuperview() }
        let page = step.content.view
        pageHost.addSubview(page)
        page.pinEdges(to: pageHost)
        dots.current = index
        dots.setAccessibilityLabel(
            String(
                localized: "Step \(index + 1) of \(steps.count)", bundle: .module, comment: "Step-by-step guide: which page is showing"))
        backButton.isHidden = flow.isFirst
        skipButton.isHidden = flow.isLast
        continueButton.title =
            flow.isLast
            ? String(localized: "Done", bundle: .module, comment: "Step-by-step guide: the last page's Continue")
            : String(localized: "Continue", bundle: .module, comment: "Step-by-step guide: go to the next page")
        onStepShown?(index)
    }

    // MARK: - Testing

    /// The heading showing, for tests.
    public var titleForTesting: String { titleLabel.stringValue }
    /// The progress VoiceOver reads ("Step 2 of 4"), for tests.
    public var progressForTesting: String { dots.accessibilityLabel() ?? "" }
    /// Continue's title, for tests.
    public var continueTitleForTesting: String { continueButton.title }
    /// Whether Back and Skip are on screen, for tests.
    public var backShownForTesting: Bool { !backButton.isHidden }
    public var skipShownForTesting: Bool { !skipButton.isHidden }
    /// The view filling the page, for tests.
    public var pageViewForTesting: NSView? { pageHost.subviews.first }
    /// Whether the page's symbol tile is showing, for tests.
    public var tileShownForTesting: Bool { !tileHost.subviews.isEmpty }
    /// Return and Escape's buttons, as their key equivalents name them, for tests.
    public var keyEquivalentsForTesting: (continue: String, skip: String) { (continueButton.keyEquivalent, skipButton.keyEquivalent) }
    /// The heading's frame in the view, for tests.
    public var titleFrameForTesting: NSRect { convert(titleLabel.bounds, from: titleLabel) }
    /// The page area's frame in the view, for tests.
    public var pageFrameForTesting: NSRect { pageHost.frame }
}
