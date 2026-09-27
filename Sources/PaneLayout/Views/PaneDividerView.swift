//
//  PaneDividerView.swift
//  PaneLayout
//
//  The ~5pt invisible hit strip centered on a pane boundary; draws the 1pt hairline at its
//  center.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import ThemedControls

/// The ~5pt invisible hit strip centered on a pane boundary; draws the 1pt hairline at
/// its center. Drag resizes the two neighboring members, double-click equalizes the axis.
public final class PaneDividerView: NSView {
    public weak var axis: PaneAxisView?
    private let index: Int

    public init(axis: PaneAxisView, index: Int) {
        self.axis = axis
        self.index = index
        super.init(frame: .zero)
        NotificationCenter.default.addObserver(
            self, selector: #selector(themeChanged), name: ThemedControls.paletteDidChange, object: nil)
    }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    public override func draw(_ dirtyRect: NSRect) {
        ThemedControls.palette.border.setFill()
        let line = axis?.orientation == .horizontal
            ? NSRect(x: bounds.midX - 0.5, y: 0, width: 1, height: bounds.height)
            : NSRect(x: 0, y: bounds.midY - 0.5, width: bounds.width, height: 1)
        line.fill()
    }

    public override func resetCursorRects() {
        addCursorRect(bounds, cursor: axis?.orientation == .horizontal ? .resizeLeftRight : .resizeUpDown)
    }

    public override func mouseDown(with event: NSEvent) {
        guard let axis else { return }
        if event.clickCount == 2 { axis.equalize(); return }
        axis.beginDividerDrag(at: index, with: event)
    }

    @objc private func themeChanged() { needsDisplay = true }
}
