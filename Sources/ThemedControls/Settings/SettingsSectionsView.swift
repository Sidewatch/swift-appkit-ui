//
//  SettingsSectionsView.swift
//  ThemedControls
//
//  Settings sections down a column — caption, card, footnote, next section — filling the width
//  it is given.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// ``SettingsSection``s laid top to bottom at the full width of the view, less `margin` each side:
/// each section's caption (inset to the card's text), its ``SettingsCard`` and its footnote. The
/// view's height is its content's. `SettingsPane.buildPane` puts one in its scrolling page; a page
/// of its own (a step of a ``StepFlowView``) uses one directly at whatever width it has.
public final class SettingsSectionsView: NSView {

    /// The sections in a column `margin` in from each side.
    public init(sections: [SettingsSection], margin: CGFloat = SettingsMetrics.margin) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        var constraints: [NSLayoutConstraint] = []
        var previous: NSView?

        /// Pins one element full width under the last; `inset` indents captions and footnotes
        /// to the card's text column.
        func place(_ element: NSView, gap: CGFloat, inset: CGFloat = 0) {
            element.translatesAutoresizingMaskIntoConstraints = false
            addSubview(element)
            constraints += [
                element.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin + inset),
                element.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(margin + inset)),
                element.topAnchor.constraint(equalTo: previous?.bottomAnchor ?? topAnchor, constant: gap),
            ]
            previous = element
        }

        for (index, section) in sections.enumerated() {
            let leading = index == 0 ? 0 : SettingsMetrics.sectionGap
            if let header = section.header {
                place(Self.header(header), gap: leading, inset: SettingsMetrics.cardInset)
                place(SettingsCard(rows: section.rows), gap: 6)
            } else {
                place(SettingsCard(rows: section.rows), gap: leading)
            }
            if let footnote = section.footnote {
                place(SettingsRowView.footnote(footnote), gap: 6, inset: SettingsMetrics.cardInset)
            }
        }
        if let previous { constraints.append(bottomAnchor.constraint(equalTo: previous.bottomAnchor)) }
        NSLayoutConstraint.activate(constraints)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// A section's caption, above its card.
    public static func header(_ text: String) -> SettingsLabel {
        let label = SettingsLabel(role: .secondary)
        label.stringValue = text
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        return label
    }
}
