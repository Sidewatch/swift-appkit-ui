//
//  CardGridView.swift
//  AppKitViews
//
//  A grid of fixed-height cards that reflows its column count to fit its width.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A grid of fixed-height cards that **reflows** its column count to fit its width: four across
/// a wide panel, stacking down to one when narrow, so a card's contents never clip.
///
/// It frames each card itself in `layout()`. The height is reported through
/// `intrinsicContentSize` and re-invalidated from `setFrameSize`, only when the column count
/// changes: invalidating from `layout()` never converges during a live resize and AppKit aborts
/// with "more layout passes than there are views".
public final class CardGridView: NSView {
    /// The cards, in order.
    public let cards: [NSView]
    /// The smallest a card may be before a column is dropped.
    public let minCardWidth: CGFloat
    /// The gap between cards, on both axes.
    public let spacing: CGFloat
    /// Every card is this tall; the grid's height is a function of the row count alone.
    public let cardHeight: CGFloat
    /// Column count last reported through `intrinsicContentSize`; the height is re-invalidated
    /// only when this changes.
    private var reportedColumns = -1

    /// Top-left origin so row 0 sits at the top.
    public override var isFlipped: Bool { true }

    /// - Parameters:
    ///   - cards: The card views, already built. The grid only ever positions them.
    ///   - minCardWidth: The smallest a card may be before a column is dropped.
    ///   - cardHeight: Every card's height.
    ///   - spacing: The gap between cards.
    public init(cards: [NSView], minCardWidth: CGFloat = 104, cardHeight: CGFloat = 62, spacing: CGFloat = 10) {
        self.cards = cards
        self.minCardWidth = minCardWidth
        self.cardHeight = cardHeight
        self.spacing = spacing
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        cards.forEach { addSubview($0) }  // default translatesAutoresizing = true → manually framed
    }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

    /// Columns that fit `width`, never more than the card count, and the rows that implies.
    /// Exposed so a host — or a test — can ask what the grid WOULD do at a width.
    public func gridShape(for width: CGFloat) -> (cols: Int, rows: Int) {
        let cols = max(1, min(cards.count, Int((width + spacing) / (minCardWidth + spacing))))
        return (cols, (cards.count + cols - 1) / cols)
    }

    /// The grid's height for `rows` rows of cards and the gaps between them.
    public func height(rows: Int) -> CGFloat {
        CGFloat(rows) * cardHeight + CGFloat(max(0, rows - 1)) * spacing
    }

    /// The grid's height is a function of its width (more columns when wide → fewer rows),
    /// reported HERE rather than by mutating a height constraint inside `layout()`.
    public override var intrinsicContentSize: NSSize {
        let w = bounds.width
        guard w > 1, !cards.isEmpty else { return NSSize(width: NSView.noIntrinsicMetric, height: cardHeight) }
        return NSSize(width: NSView.noIntrinsicMetric, height: height(rows: gridShape(for: w).rows))
    }

    /// Re-invalidates the height only when the width crosses a column-count boundary, from the
    /// sizing phase so the new height joins the same solve. Must not move into `layout()` (see
    /// the type doc).
    public override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        guard !cards.isEmpty else { return }
        let cols = gridShape(for: newSize.width).cols
        if cols != reportedColumns {
            reportedColumns = cols
            invalidateIntrinsicContentSize()
        }
    }

    public override func layout() {
        super.layout()  // frames the cards only — never invalidates or mutates a constraint
        let w = bounds.width
        guard w > 1, !cards.isEmpty else { return }
        let cols = gridShape(for: w).cols
        let cw = ((w - CGFloat(cols - 1) * spacing) / CGFloat(cols)).rounded(.down)
        for (i, card) in cards.enumerated() {
            let row = i / cols, col = i % cols
            card.frame = NSRect(
                x: CGFloat(col) * (cw + spacing),
                y: CGFloat(row) * (cardHeight + spacing),
                width: cw, height: cardHeight)
        }
    }
}
