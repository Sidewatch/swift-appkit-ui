//
//  SettingsRowView.swift
//  ThemedControls
//
//  One card row. Either a caption on the leading edge with its control on the trailing edge — the
//  platform's settings idiom — or a custom view spanning the card for content that isn't a
//  caption/control pair.
//
//  Created by David Sherlock on 9/5/26.
//

import AppKit

/// One card row. Either a caption on the leading edge with its control on the
/// trailing edge — the platform's settings idiom — or a custom view spanning the
/// card for content that isn't a caption/control pair.
public final class SettingsRowView: NSView {

    /// The row's caption, for the label/control form. Nil for a spanning row.
    private let label: SettingsLabel?

    /// Set by ``SettingsCard`` so hiding a row also collapses the space it occupied.
    ///
    /// `isHidden` stops a view drawing but leaves its constraints intact, so a hidden row left
    /// an empty band and a stray separator in the middle of the card — visible as a gap under
    /// Size when the font size was not Custom.
    public var onHiddenChanged: ((Bool) -> Void)?

    public override var isHidden: Bool {
        didSet { if oldValue != isHidden { onHiddenChanged?(isHidden) } }
    }

    /// A caption/control row, with optional tertiary copy beneath.
    ///
    /// The footnote spans the row rather than tucking under the caption, so it
    /// wraps at the card's text width — the one width the panes can state
    /// exactly.
    ///
    /// Footnotes are kept to about a line and say what you must know to choose correctly — a
    /// prerequisite, a caveat, the thing that makes the setting look broken if you do not know
    /// it. Longer explanations of how a setting works internally are deliberately absent rather
    /// than hidden behind a tooltip: a tooltip is only read by someone who already suspects
    /// there is more to find, so it is the wrong place for anything that matters and dead weight
    /// for anything that does not.
    public init(_ title: String, control: NSView, footnote: String? = nil) {
        let caption = SettingsLabel(role: .primary)
        caption.stringValue = title
        caption.font = .systemFont(ofSize: 12)
        // A long caption truncates rather than shoving the control off the row.
        caption.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label = caption
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        control.translatesAutoresizingMaskIntoConstraints = false
        control.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(caption)
        addSubview(control)
        // VoiceOver: a switch, slider, popup or field in a row is named by the row's caption —
        // without it a switch reads as "switch, on" with no subject (19 Sep 2026). A text button
        // already says what it does ("Browse…") and keeps its own title.
        let keepsOwnName = (control as? NSButton).map { !$0.title.isEmpty && !($0 is NSPopUpButton) } ?? false
        if !keepsOwnName { control.setAccessibilityLabel(title) }

        // The control line is a guide, not a view: the caption and control are
        // centered in a known height, so a stepper and a label sit on one
        // baseline-neutral line without either dictating the row's height.
        let line = NSLayoutGuide()
        addLayoutGuide(line)

        var constraints: [NSLayoutConstraint] = [
            line.topAnchor.constraint(equalTo: topAnchor, constant: SettingsMetrics.rowPadding),
            line.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SettingsMetrics.cardInset),
            line.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -SettingsMetrics.cardInset),
            line.heightAnchor.constraint(equalToConstant: SettingsMetrics.rowLineHeight),

            caption.leadingAnchor.constraint(equalTo: line.leadingAnchor),
            caption.centerYAnchor.constraint(equalTo: line.centerYAnchor),
            control.trailingAnchor.constraint(equalTo: line.trailingAnchor),
            control.centerYAnchor.constraint(equalTo: line.centerYAnchor),
            control.leadingAnchor.constraint(greaterThanOrEqualTo: caption.trailingAnchor, constant: 12),
        ]

        if let footnote {
            let note = SettingsRowView.footnote(footnote)
            addSubview(note)
            constraints += [
                note.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SettingsMetrics.cardInset),
                note.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -SettingsMetrics.cardInset),
                note.topAnchor.constraint(equalTo: line.bottomAnchor, constant: 2),
                note.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -SettingsMetrics.rowPadding),
            ]
        } else {
            constraints.append(line.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                            constant: -SettingsMetrics.rowPadding))
        }
        NSLayoutConstraint.activate(constraints)
    }




    /// A row whose `content` spans the card — a list, or a button bar. `inset`
    /// and `padding` default to the card's text margins; pass 0 for content that
    /// should reach the card's edges, like a list that fills it.
    public init(spanning content: NSView,
         inset: CGFloat = SettingsMetrics.cardInset,
         padding: CGFloat = SettingsMetrics.rowPadding) {
        label = nil
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            content.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Dims the row's caption alongside a control the pane has disabled. AppKit
    /// dims the control but leaves the caption at full strength, which reads as a
    /// live row over a dead control. The footnote keeps its color — it is what
    /// explains the row being off.
    public func setEnabled(_ enabled: Bool) {
        label?.setDimmed(!enabled)
    }

    /// Tertiary explanatory copy, wrapped to the card's text column.
    public static func footnote(_ text: String) -> SettingsLabel {
        let note = SettingsLabel(role: .tertiary, wrapping: true)
        note.stringValue = text
        note.font = .systemFont(ofSize: 11)
        note.preferredMaxLayoutWidth = SettingsMetrics.cardTextWidth
        note.setContentCompressionResistancePriority(.required, for: .vertical)
        return note
    }
}
