//
//  SettingsCard.swift
//  ThemedControls
//
//  A grouped-form card: the rounded, hairline-bordered container a section's rows sit in, proud
//  of the recessed page behind it.
//
//  Created by David Sherlock on 9/5/26.
//

import AppKit

/// A grouped-form card: the rounded, hairline-bordered container a section's
/// rows sit in, proud of the recessed page behind it.
///
/// The fill and border are drawn rather than set as layer colors: `Theme` colors
/// change on `ThemedControls.paletteDidChange` (a new palette, not only a light/dark flip), and a
/// `CGColor` snapshotted into a layer would freeze at the palette it was taken
/// under. Drawing re-reads `Theme` on every pass, and the card redraws on both a
/// theme change and an appearance flip.
public final class SettingsCard: NSView {

    /// Stacks `rows` top to bottom, separated by hairlines, and takes its height
    /// from them.
    public init(rows: [NSView]) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        // Clips a first/last row's own drawing (the skip list's selected row) to
        // the card's corners.
        wantsLayer = true
        layer?.cornerRadius = SettingsMetrics.cardRadius
        layer?.masksToBounds = true
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged),
                                               name: ThemedControls.paletteDidChange, object: nil)

        var constraints: [NSLayoutConstraint] = []
        var previous: NSView?

        for row in rows {
            if previous != nil {
                let separator = SettingsSeparatorView()
                addSubview(separator)
                constraints += span(separator, under: previous)
                // A true hairline. `1` here is one *point* — two device pixels on
                // Retina, i.e. double a native separator, which made the old
                // too-dark fill twice as loud. The card's border already accounts
                // for this (see its `insetBy(dx: 0.5)`); this never did.
                constraints.append(separator.heightAnchor.constraint(equalToConstant: SettingsMetrics.hairline))
                previous = separator
            }
            row.translatesAutoresizingMaskIntoConstraints = false
            addSubview(row)
            constraints += span(row, under: previous)

            // A hidden row must give back its height and take its separator with it, or the card
            // keeps a blank band where it used to be. The zero-height constraint stays inactive
            // while the row is visible so it never fights the row's real content.
            if let settingsRow = row as? SettingsRowView {
                let collapse = settingsRow.heightAnchor.constraint(equalToConstant: 0)
                let separatorAbove = previous as? SettingsSeparatorView
                settingsRow.onHiddenChanged = { hidden in
                    collapse.isActive = hidden
                    separatorAbove?.isHidden = hidden
                }
                if settingsRow.isHidden {
                    collapse.isActive = true
                    separatorAbove?.isHidden = true
                }
            }
            previous = row
        }
        if let last = previous {
            constraints.append(last.bottomAnchor.constraint(equalTo: bottomAnchor))
        }
        NSLayoutConstraint.activate(constraints)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { NotificationCenter.default.removeObserver(self) }

    /// Pins `element` edge to edge under `previous` — or to the card's top when
    /// it is the first element.
    private func span(_ element: NSView, under previous: NSView?) -> [NSLayoutConstraint] {
        [
            element.leadingAnchor.constraint(equalTo: leadingAnchor),
            element.trailingAnchor.constraint(equalTo: trailingAnchor),
            element.topAnchor.constraint(equalTo: previous?.bottomAnchor ?? topAnchor),
        ]
    }

    public override func draw(_ dirtyRect: NSRect) {
        // Inset by half the line width so the stroke lands on the card's edge
        // rather than straddling it (a straddled hairline reads as 2px, blurred).
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
                                xRadius: SettingsMetrics.cardRadius,
                                yRadius: SettingsMetrics.cardRadius)
        SettingsMetrics.cardFill.setFill()
        path.fill()
        ThemedControls.palette.border.setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    /// A theme change (`ThemedControls.paletteDidChange`) or an appearance flip both change the
    /// drawn fill/border; the card only follows if it redraws.
    @objc private func themeChanged() { needsDisplay = true }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}
