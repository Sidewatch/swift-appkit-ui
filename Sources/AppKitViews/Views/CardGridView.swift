//
//  CardGridView.swift
//  AppKitViews
//
//  A grid of fixed-height cards that reflows its column count to fit its width.
//
//  Created by David Sherlock on 9/26/26.
//

import AppKit

/// A grid of fixed-height cards that **reflows** its column count to fit its width: four across
/// a wide panel, stacking down to one when narrow, so a card's contents never clip.
///
/// It frames each card itself in `layout()`; the cards carry no size of their own.
///
/// **The height is reported through `intrinsicContentSize` and re-invalidated from
/// `setFrameSize`, and that is not a style choice.** A width-to-height view that invalidates
/// from inside `layout()` re-dirties itself mid-pass, and during a continuous resize or zoom
/// that never converges — AppKit aborts with "more layout passes than there are views". Doing
/// it in the sizing phase folds the new height into the SAME solve. The other half of the rule
/// is that the height must change at a few DISCRETE breakpoints: this one re-invalidates only
/// when the column count changes, so a continuous drag crosses a handful of them rather than
/// reporting a new height every pixel.
public final class CardGridView: NSView {
    /// The cards, in order.
    public let cards: [NSView]
    /// The smallest a card may be before a column is dropped.
    public let minCardWidth: CGFloat
    /// The gap between cards, on both axes.
    public let spacing: CGFloat
    /// Every card is this tall; the grid's height is a function of the row count alone.
    public let cardHeight: CGFloat
    /// Column count last reported through `intrinsicContentSize`. The grid's height only
    /// changes when the column count does, so we re-invalidate on that — from `setFrameSize`,
    /// never from `layout()`.
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
        cards.forEach { addSubview($0) }   // default translatesAutoresizing = true → manually framed
    }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

    /// Columns that fit `width`, never more than the card count, and the rows that implies.
    /// Exposed so a host — or a test — can ask what the grid WOULD do at a width.
    public func gridShape(for width: CGFloat) -> (cols: Int, rows: Int) {
        let cols = max(1, min(cards.count, Int((width + spacing) / (minCardWidth + spacing))))
        return (cols, (cards.count + cols - 1) / cols)
    }

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

    /// Re-invalidate the intrinsic (height) ONLY when the width crosses a column-count
    /// boundary, and do it from `setFrameSize` — the sizing phase, before `layout()`.
    /// Invalidating from inside `layout()` re-dirties the view mid-pass; during a continuous
    /// resize/zoom animation that never converges and trips AppKit's "more layout passes than
    /// views" abort (the Usage crash). setFrameSize folds the new height into the SAME solve.
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
        super.layout()   // frames the cards only — never invalidates or mutates a constraint
        let w = bounds.width
        guard w > 1, !cards.isEmpty else { return }
        let cols = gridShape(for: w).cols
        let cw = ((w - CGFloat(cols - 1) * spacing) / CGFloat(cols)).rounded(.down)
        for (i, card) in cards.enumerated() {
            let row = i / cols, col = i % cols
            card.frame = NSRect(x: CGFloat(col) * (cw + spacing),
                                y: CGFloat(row) * (cardHeight + spacing),
                                width: cw, height: cardHeight)
        }
    }
}
