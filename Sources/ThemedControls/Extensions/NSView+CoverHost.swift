//
//  NSView+CoverHost.swift
//  ThemedControls
//
//  Pins a state view centred over the area it speaks for.
//
//  Created by David Sherlock on 10/22/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

extension NSView {
    /// Pins this view centred over `host` (a scroll view or table area) in `host`'s own superview,
    /// starting hidden. The host's layout is untouched: a state only ever covers it, so revealing
    /// one cannot reflow the panel. Nothing happens when `host` has no superview yet.
    ///
    /// A host that is a pane of a split view is covered from the split's own superview: a split
    /// arranges every subview it is given, so a cover added to it would become a third pane, holding
    /// the host at its minimum height.
    func coverCentred(over host: NSView) {
        guard var parent = host.superview else { return }
        while let split = parent as? NSSplitView, split.arrangesAllSubviews {
            guard let outer = split.superview else { return }
            parent = outer
        }
        isHidden = true
        parent.addSubview(self, positioned: .above, relativeTo: parent === host.superview ? host : nil)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 20),
            trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -20),
            centerYAnchor.constraint(equalTo: host.centerYAnchor),
        ])
    }
}
