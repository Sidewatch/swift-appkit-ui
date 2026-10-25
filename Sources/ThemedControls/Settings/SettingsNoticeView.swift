//
//  SettingsNoticeView.swift
//  ThemedControls
//
//  A line inside a settings card saying why the rows around it are off, and what turns them on.
//
//  Created by David Sherlock on 10/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// An accent `info.circle` beside one or two lines of secondary text, for a card row that explains
/// a dimmed page ("Agent features are off, so …"). Host it in `SettingsRowView(spanning:)` and hide
/// the ROW while there is nothing to explain.
public final class SettingsNoticeView: NSView {
    private let symbolView = NSImageView()
    private let label = SettingsLabel(role: .secondary, wrapping: true)

    /// A notice reading `text`.
    public init(_ text: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        symbolView.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        symbolView.symbolConfiguration = .init(pointSize: 13, weight: .regular)
        symbolView.contentTintColor = ThemedControls.palette.accent
        symbolView.setContentHuggingPriority(.required, for: .horizontal)
        label.stringValue = text
        label.font = .systemFont(ofSize: 12)
        label.preferredMaxLayoutWidth = SettingsMetrics.cardTextWidth - 24
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubviewsForAutoLayout(symbolView, label)
        NSLayoutConstraint.activate([
            symbolView.leadingAnchor.constraint(equalTo: leadingAnchor),
            symbolView.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            label.leadingAnchor.constraint(equalTo: symbolView.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
        setAccessibilityLabel(text)
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: ThemedControls.paletteDidChange, object: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func themeChanged() { symbolView.contentTintColor = ThemedControls.palette.accent }

    /// The text shown, for tests.
    public var textForTesting: String { label.stringValue }
}
