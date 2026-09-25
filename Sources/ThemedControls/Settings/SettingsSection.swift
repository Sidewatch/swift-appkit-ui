//
//  SettingsSection.swift
//  ThemedControls
//
//  One settings group, in the grouped-form idiom: an optional caption over a card of rows, with
//  optional tertiary copy beneath it.
//
//  Created by David Sherlock on 9/5/26.
//

import AppKit

/// One settings group, in the grouped-form idiom: an optional caption over a
/// card of rows, with optional tertiary copy beneath it.
public struct SettingsSection {
    /// The caption above the card. Nil for a lone card that needs no name.
    public let header: String?
    /// The card's rows, hairline-separated in order.
    public let rows: [NSView]
    /// Tertiary copy under the card — for a caveat that belongs to the whole
    /// group rather than to one row.
    public let footnote: String?

    public init(header: String? = nil, rows: [NSView], footnote: String? = nil) {
        self.header = header
        self.rows = rows
        self.footnote = footnote
    }
}
