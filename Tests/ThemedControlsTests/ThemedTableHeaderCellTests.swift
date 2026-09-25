//
//  ThemedTableHeaderCellTests.swift
//  ThemedControlsTests
//
//  Renders a real table header and reads the pixels back: the themed cell must paint the
//  palette, where the stock cell paints a system grey over it.
//
//  Created by David Sherlock on 9/17/26.
//

import XCTest
@testable import ThemedControls

/// Tests for `ThemedTableHeaderCell`. These render the header through AppKit and sample the
/// bitmap, because the bug they cover is a drawing one: `ThemedTableHeaderView` filled the
/// palette colour correctly all along and `NSTableHeaderCell` painted over it.
@MainActor
final class ThemedTableHeaderCellTests: XCTestCase {

    /// Colours chosen so nothing else in AppKit's palette can be mistaken for them.
    private struct Loud: ControlPalette {
        var isDark: Bool { true }
        var accent: NSColor { .systemPink }
        var foreground: NSColor { .white }
        var selection: NSColor { .systemBlue }
        var sidebarBackground: NSColor { NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1) }
        var sidebarText: NSColor { .lightGray }
        var statusText: NSColor { .lightGray }
        var border: NSColor { NSColor(srgbRed: 0, green: 1, blue: 0, alpha: 1) }          // #00FF00
        var rowSeparator: NSColor { NSColor(srgbRed: 0, green: 0, blue: 1, alpha: 1) }    // #0000FF
        var mutedText: NSColor { .gray }
        var statusBackground: NSColor { NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1) } // #FF0000
        var smallFont: NSFont { .systemFont(ofSize: 11, weight: .medium) }
        func elevatedSurface(dark: CGFloat, light: CGFloat) -> NSColor { .darkGray }
    }

    override func setUp() {
        super.setUp()
        ThemedControls.palette = Loud()
    }

    override func tearDown() {
        ThemedControls.palette = SystemPalette()
        super.tearDown()
    }

    private static let size = NSSize(width: 200, height: 24)

    /// A table whose FIRST column uses `cell`, laid out and rendered into a bitmap. `columns`
    /// says how many there are, because a divider is drawn between two columns and never after
    /// the last one — with a single column there is nothing to divide (25 Sep 2026).
    ///
    /// `bitmapImageRepForCachingDisplay` allocates at the BACKING scale, so the rep is 2× the
    /// view on this machine and every sample below is taken in POINTS and scaled — a pixel
    /// coordinate read as a point coordinate lands in the middle of the cell and quietly
    /// samples the fill instead of the hairline it was aiming at.
    private func renderedHeader(cell: NSTableHeaderCell, columns: Int = 1) -> NSBitmapImageRep {
        let table = NSTableView(frame: NSRect(origin: .zero, size: NSSize(width: Self.size.width, height: 100)))
        // `.plain` with no intercell spacing makes the header rect exactly the column rect;
        // the default `.automatic` style insets it by 10pt at each end and the samples below
        // would land in the filler strips instead of the column.
        table.style = .plain
        table.intercellSpacing = .zero
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("c"))
        column.width = Self.size.width
        column.headerCell = cell
        table.addTableColumn(column)
        for i in 1..<max(1, columns) {
            let extra = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("c\(i)"))
            extra.width = Self.size.width
            extra.headerCell = ThemedTableHeaderCell(title: "x")
            table.addTableColumn(extra)
        }
        let header = ThemedTableHeaderView()
        header.tableView = table
        table.headerView = header
        header.frame = NSRect(origin: .zero, size: Self.size)
        header.layoutSubtreeIfNeeded()
        let rep = header.bitmapImageRepForCachingDisplay(in: header.bounds)!
        header.cacheDisplay(in: header.bounds, to: rep)
        return rep
    }

    /// The same palette colour taken through the same render path, so the comparison is
    /// unaffected by the bitmap's colour space (a display-P3 backing store does not read back
    /// as the sRGB values that went in).
    private func rendered(_ color: NSColor) -> NSColor {
        final class Swatch: NSView {
            var color: NSColor = .black
            override func draw(_ dirtyRect: NSRect) { color.setFill(); dirtyRect.fill() }
        }
        let swatch = Swatch(frame: NSRect(origin: .zero, size: Self.size))
        swatch.color = color
        let rep = swatch.bitmapImageRepForCachingDisplay(in: swatch.bounds)!
        swatch.cacheDisplay(in: swatch.bounds, to: rep)
        return sample(rep, 100, 12)
    }

    /// The colour at a POINT in a rep that may be at any backing scale.
    private func sample(_ rep: NSBitmapImageRep, _ x: CGFloat, _ y: CGFloat) -> NSColor {
        let scale = CGFloat(rep.pixelsWide) / Self.size.width
        let px = min(rep.pixelsWide - 1, Int((x * scale).rounded(.down)))
        let py = min(rep.pixelsHigh - 1, Int((y * scale).rounded(.down)))
        return rep.colorAt(x: px, y: py)!
    }

    private func assertSameColor(_ a: NSColor, _ b: NSColor, _ message: String,
                                 file: StaticString = #filePath, line: UInt = #line) {
        let x = a.usingColorSpace(.sRGB)!, y = b.usingColorSpace(.sRGB)!
        for (l, r) in [(x.redComponent, y.redComponent), (x.greenComponent, y.greenComponent), (x.blueComponent, y.blueComponent)] {
            XCTAssertEqual(l, r, accuracy: 0.03, "\(message) — got \(x), want \(y)", file: file, line: line)
        }
    }

    // MARK: - The bug

    func testTheThemedCellPaintsThePaletteWhereTheStockCellPaintsASystemGrey() {
        let want = rendered(Loud().statusBackground)
        let themed = sample(renderedHeader(cell: ThemedTableHeaderCell(title: "id")), 150, 8)
        assertSameColor(themed, want, "the header band must be the palette's status background")

        // The mutation check, run as part of the test rather than by hand: the stock cell is
        // the code this class replaces, and it must NOT produce that colour — otherwise this
        // test would pass with the fix reverted.
        let stock = sample(renderedHeader(cell: NSTableHeaderCell(textCell: "id")), 150, 8)
        let drift = abs(stock.redComponent - want.redComponent)
            + abs(stock.greenComponent - want.greenComponent)
            + abs(stock.blueComponent - want.blueComponent)
        XCTAssertGreaterThan(drift, 0.1,
                             "the stock cell paints its own background — if it matched the palette there would be nothing to fix (got \(stock))")
    }

    func testTheBottomHairlineIsTheBorderColourAndTheColumnDividerIsTheRowSeparator() {
        // TWO columns, so the first has a neighbour to be divided from.
        let rep = renderedHeader(cell: ThemedTableHeaderCell(title: "id"), columns: 2)
        assertSameColor(sample(rep, 100, 23.5), rendered(Loud().border),
                        "bottom hairline separates the header from row 1")
        assertSameColor(sample(rep, 199.5, 12), rendered(Loud().rowSeparator),
                        "column divider between the first column and the second")
    }

    /// A divider divides two columns. The LAST column's trailing edge is the table's own edge,
    /// and ruling it drew a frame rather than a grid (25 Sep 2026, David of the CSV preview:
    /// "should the furthest left one have another separator line? probably not").
    func testTheLastColumnIsNotRuledOffAtItsTrailingEdge() {
        let rep = renderedHeader(cell: ThemedTableHeaderCell(title: "id"))   // one column: it IS the last
        assertSameColor(sample(rep, 199.5, 12), rendered(Loud().statusBackground),
                        "the header's own trailing edge carries no divider")
    }

    func testAPressedHeaderLightensRatherThanKeepingTheRestingFill() {
        let cell = ThemedTableHeaderCell(title: "id")
        cell.isHighlighted = true
        let pressed = sample(renderedHeader(cell: cell), 150, 8).usingColorSpace(.sRGB)!
        let resting = rendered(Loud().statusBackground).usingColorSpace(.sRGB)!
        XCTAssertGreaterThan(pressed.greenComponent + pressed.blueComponent,
                             resting.greenComponent + resting.blueComponent + 0.02,
                             "a click must lift the fill toward the foreground, or the header reads as dead")

        // The system pressed grey must not be what comes back: `drawInterior` paints one when
        // the cell is highlighted, which is why the fix drops the flag around the title draw.
        XCTAssertGreaterThan(pressed.redComponent - pressed.greenComponent, 0.4,
                             "a pressed header stayed in the palette rather than turning system grey (got \(pressed))")
    }

    func testTheTitleIsThePalettesColourOneWeightStepUpFromItsSmallFont() {
        let title = ThemedTableHeaderCell.title("id")
        let attrs = title.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(attrs[.foregroundColor] as? NSColor, Loud().statusText)
        let font = attrs[.font] as! NSFont
        XCTAssertEqual(font.pointSize, Loud().smallFont.pointSize, "same size as the palette's small font")
        let weight = { (f: NSFont) in
            (f.fontDescriptor.object(forKey: .traits) as? [NSFontDescriptor.TraitKey: Any])?[.weight] as? CGFloat ?? 0
        }
        XCTAssertGreaterThan(weight(font), weight(Loud().smallFont), "a column title reads as a label, not as caption text")
    }

    func testTitleInsetMovesTheTitleWithoutMovingTheBandOrTheHairlines() {
        func inkStart(_ cell: NSTableHeaderCell) -> CGFloat? {
            let rep = renderedHeader(cell: cell)
            let scale = CGFloat(rep.pixelsWide) / Self.size.width
            let band = sample(rep, 150, 8).usingColorSpace(.sRGB)!
            for px in 0..<rep.pixelsWide {
                for py in stride(from: Int(6 * scale), to: Int(18 * scale), by: 1) {
                    guard let c = rep.colorAt(x: px, y: py)?.usingColorSpace(.sRGB) else { continue }
                    let drift = abs(c.redComponent - band.redComponent) + abs(c.greenComponent - band.greenComponent) + abs(c.blueComponent - band.blueComponent)
                    if drift > 0.10 { return CGFloat(px) / scale }
                }
            }
            return nil
        }
        let plain = try! XCTUnwrap(inkStart(ThemedTableHeaderCell(title: "id")))
        let inset = try! XCTUnwrap(inkStart(ThemedTableHeaderCell(title: "id", titleInset: 6)))
        XCTAssertEqual(inset - plain, 6, accuracy: 1.0, "the title moves by the inset it was given")

        let rep = renderedHeader(cell: ThemedTableHeaderCell(title: "id", titleInset: 6))
        assertSameColor(sample(rep, 150, 8), rendered(Loud().statusBackground), "the band still starts at the column's edge")
        assertSameColor(sample(rep, 2, 23.5), rendered(Loud().border), "and the hairline still spans it")
    }

    func testTheTitleIsVerticallyCentredInTheBandLikeTheStockCells() {
        // Ink rows of the title (the statusText grey against the red band), in points.
        func inkCentre(_ cell: NSTableHeaderCell, height: CGFloat) -> CGFloat {
            let table = NSTableView(frame: NSRect(origin: .zero, size: NSSize(width: Self.size.width, height: 100)))
            table.style = .plain; table.intercellSpacing = .zero
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("c"))
            column.width = Self.size.width; column.headerCell = cell
            table.addTableColumn(column)
            let header = ThemedTableHeaderView(); header.tableView = table; table.headerView = header
            header.frame = NSRect(x: 0, y: 0, width: Self.size.width, height: height)
            header.layoutSubtreeIfNeeded()
            let rep = header.bitmapImageRepForCachingDisplay(in: header.bounds)!
            header.cacheDisplay(in: header.bounds, to: rep)
            let scale = CGFloat(rep.pixelsWide) / Self.size.width
            var minY = Int.max, maxY = -1
            for y in 0..<rep.pixelsHigh { for x in 0..<rep.pixelsWide {
                guard let c = rep.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
                if c.greenComponent > 0.4 && c.blueComponent > 0.4 { minY = min(minY, y); maxY = max(maxY, y) }
            } }
            return CGFloat(minY + maxY) / 2 / scale
        }
        for height: CGFloat in [24, 28] {
            let themed = inkCentre(ThemedTableHeaderCell(title: "id"), height: height)
            let stock = inkCentre(NSTableHeaderCell(textCell: "id"), height: height)
            XCTAssertEqual(themed, height / 2, accuracy: 1.5, "title centred in a \(Int(height))pt header (ink centre \(themed))")
            XCTAssertEqual(themed, stock, accuracy: 1.5, "and where the stock cell puts it (\(stock))")
        }
    }

    // MARK: - The sort indicator the override would otherwise lose

    func testTheSortIndicatorFollowsTheTablesOwnSortState() {
        let table = NSTableView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("c"))
        let cell = ThemedTableHeaderCell(title: "id")
        column.headerCell = cell
        column.sortDescriptorPrototype = NSSortDescriptor(key: "c", ascending: true)
        table.addTableColumn(column)
        let header = ThemedTableHeaderView()
        header.tableView = table
        table.headerView = header

        XCTAssertNil(cell.sortIndicatorAscending(in: header), "no indicator until the table sets one")

        table.setIndicatorImage(NSImage(named: "NSAscendingSortIndicator"), in: column)
        table.sortDescriptors = [NSSortDescriptor(key: "c", ascending: true)]
        XCTAssertEqual(cell.sortIndicatorAscending(in: header), true)

        table.sortDescriptors = [NSSortDescriptor(key: "c", ascending: false)]
        XCTAssertEqual(cell.sortIndicatorAscending(in: header), false, "the arrow follows the descriptor, not the image")
    }
}
