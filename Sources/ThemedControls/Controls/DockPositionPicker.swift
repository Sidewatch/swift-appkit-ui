//
//  DockPositionPicker.swift
//  ThemedControls
//
//  A row of `DockPositionTile`s, one per position: where a docked panel goes, shown rather than
//  named.
//
//  Created by David Sherlock on 10/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// The positions side by side, each a drawing of the window with the panel there. The host
/// names them, sets ``selected`` and acts on ``onPick``; a pick also rings the tile picked.
public final class DockPositionPicker: NSView {
    /// The tiles, in ``DockPosition`` order.
    public private(set) var tiles: [DockPositionTile] = []

    /// The ringed position.
    public var selected: DockPosition = .bottom { didSet { ringSelected() } }

    /// Whether the panel is shown at all (drawn as an outline while off).
    public var showsPanel = true {
        didSet { for tile in tiles { tile.showsPanel = showsPanel } }
    }

    /// A tile was picked.
    public var onPick: ((DockPosition) -> Void)?

    private static let spacing: CGFloat = 12

    /// A picker `width` points wide, each position named by `title`.
    public init(width: CGFloat, title: (DockPosition) -> String) {
        super.init(frame: .zero)
        let tileWidth = (width - Self.spacing * CGFloat(DockPosition.allCases.count - 1)) / CGFloat(DockPosition.allCases.count)
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = Self.spacing
        for position in DockPosition.allCases {
            let tile = DockPositionTile(position: position, title: title(position), width: tileWidth)
            tile.onPick = { [weak self] in
                self?.selected = position
                self?.onPick?(position)
            }
            tiles.append(tile)
            stack.addArrangedSubview(tile)
        }
        addSubviewsForAutoLayout(stack)
        stack.pinEdges(to: self)
        setAccessibilityElement(true)
        setAccessibilityRole(.radioGroup)
        ringSelected()  // an init's own assignment runs no didSet
    }

    private func ringSelected() { for tile in tiles { tile.isPicked = tile.position == selected } }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
