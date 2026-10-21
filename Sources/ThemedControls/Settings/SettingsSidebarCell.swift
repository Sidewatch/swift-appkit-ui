//
//  SettingsSidebarCell.swift
//  ThemedControls
//
//  One page row of a settings sidebar: a symbol and a title.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// Symbol + title; the colours follow the selection.
public final class SettingsSidebarCell: NSTableCellView {
    /// The reuse identifier.
    public static let identifier = NSUserInterfaceItemIdentifier("SettingsSidebarCell")
    /// The page's symbol.
    public let icon = NSImageView()
    /// The page's title.
    public let label = NSTextField(labelWithString: "")

    /// An empty cell; ``configure(title:symbol:)`` fills it.
    public init() {
        super.init(frame: .zero)
        identifier = Self.identifier
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        icon.imageScaling = .scaleProportionallyDown
        label.font = .systemFont(ofSize: 13)
        label.lineBreakMode = .byTruncatingTail
        addSubviewsForAutoLayout(icon, label)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 18),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        textField = label
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    /// Shows `title` beside the SF Symbol `symbol`.
    public func configure(title: String, symbol: String) {
        label.stringValue = title
        icon.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        icon.setAccessibilityElement(false)  // the title speaks for the row
    }

    /// Recolours the symbol and title to read on the accent fill when selected.
    public func setSelected(_ selected: Bool) {
        label.textColor = selected ? ThemedControls.palette.onAccent : ThemedControls.palette.sidebarText
        icon.contentTintColor = selected ? ThemedControls.palette.onAccent : ThemedControls.palette.sidebarText.withAlphaComponent(0.85)
    }
}
