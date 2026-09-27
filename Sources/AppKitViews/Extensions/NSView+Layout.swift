//
//  NSView+Layout.swift
//  AppKitViews
//
//  Adding subviews for Auto Layout and pinning them in one call.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSView {
    /// Adds each view as a subview laid out by constraints (its autoresizing mask off).
    func addSubviewsForAutoLayout(_ views: NSView...) {
        addSubviewsForAutoLayout(views)
    }

    /// Adds each view as a subview laid out by constraints (its autoresizing mask off).
    func addSubviewsForAutoLayout(_ views: [NSView]) {
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
    }

    /// Adds `view` for Auto Layout and pins the chosen edges to this view, activated.
    @discardableResult
    func addPinnedSubview(
        _ view: NSView,
        insets: NSDirectionalEdgeInsets = .init(),
        edges: NSDirectionalRectEdge = .all
    ) -> [NSLayoutConstraint] {
        addSubviewsForAutoLayout(view)
        return view.pinEdges(to: self, insets: insets, edges: edges)
    }

    /// Pins the chosen edges to `other`, inset inward by `insets`, and activates them. Turns
    /// this view's autoresizing mask off.
    @discardableResult
    func pinEdges(
        to other: LayoutAnchoring,
        insets: NSDirectionalEdgeInsets = .init(),
        edges: NSDirectionalRectEdge = .all,
        priority: NSLayoutConstraint.Priority = .required
    ) -> [NSLayoutConstraint] {
        let constraints = edgeConstraints(to: other, insets: insets, edges: edges, priority: priority)
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    /// The constraints ``pinEdges(to:insets:edges:priority:)`` would activate, NOT activated,
    /// for a caller that activates one combined list. Turns the autoresizing mask off.
    func edgeConstraints(
        to other: LayoutAnchoring,
        insets: NSDirectionalEdgeInsets = .init(),
        edges: NSDirectionalRectEdge = .all,
        priority: NSLayoutConstraint.Priority = .required
    ) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        var constraints: [NSLayoutConstraint] = []
        if edges.contains(.top) { constraints.append(topAnchor.constraint(equalTo: other.topAnchor, constant: insets.top)) }
        if edges.contains(.leading) { constraints.append(leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: insets.leading)) }
        if edges.contains(.bottom) { constraints.append(bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -insets.bottom)) }
        if edges.contains(.trailing) {
            constraints.append(trailingAnchor.constraint(equalTo: other.trailingAnchor, constant: -insets.trailing))
        }
        for c in constraints { c.priority = priority }
        return constraints
    }

    /// Fixes the width and/or height, activated. Turns the autoresizing mask off.
    @discardableResult
    func pinSize(
        width: CGFloat? = nil, height: CGFloat? = nil,
        priority: NSLayoutConstraint.Priority = .required
    ) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        var constraints: [NSLayoutConstraint] = []
        if let width { constraints.append(widthAnchor.constraint(equalToConstant: width)) }
        if let height { constraints.append(heightAnchor.constraint(equalToConstant: height)) }
        for c in constraints { c.priority = priority }
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    /// Centres this view in `other` on the chosen axes, offset by `offset`, activated.
    @discardableResult
    func pinCenter(
        to other: LayoutAnchoring, x: Bool = true, y: Bool = true,
        offset: CGPoint = .zero
    ) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        var constraints: [NSLayoutConstraint] = []
        if x { constraints.append(centerXAnchor.constraint(equalTo: other.centerXAnchor, constant: offset.x)) }
        if y { constraints.append(centerYAnchor.constraint(equalTo: other.centerYAnchor, constant: offset.y)) }
        NSLayoutConstraint.activate(constraints)
        return constraints
    }
}
