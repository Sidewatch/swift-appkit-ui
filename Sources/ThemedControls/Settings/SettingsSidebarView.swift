//
//  SettingsSidebarView.swift
//  ThemedControls
//
//  A settings window's page list down its left edge.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A settings window's page list, System Settings' layout: a table of pages down the window's
/// left edge on the palette's sidebar surface, each row an SF Symbol and a title, the selected row a
/// rounded accent fill. Selection reaches the controller through `onSelect`;
/// `select(_:notify:)` moves it without echoing.
public final class SettingsSidebarView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    /// Fired with the page index when the user picks a row.
    public var onSelect: ((Int) -> Void)?
    /// The page table (exposed for the harnesses).
    public let table = NSTableView()
    private let scroll = NSScrollView()
    private let pages: [(title: String, symbol: String)]
    /// Set while a selection change must not reach `onSelect` (programmatic moves, reloads).
    private var suppress = false
    /// A row's height.
    public static let rowHeight: CGFloat = 28

    /// A list of `pages`, each a title and an SF Symbol name, in order.
    public init(pages: [(title: String, symbol: String)]) {
        self.pages = pages
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("page"))
        column.resizingMask = .autoresizingMask
        table.addTableColumn(column)
        table.headerView = nil
        table.rowHeight = Self.rowHeight
        table.intercellSpacing = NSSize(width: 0, height: 2)
        table.selectionHighlightStyle = .none  // the row view draws the accent fill
        table.allowsEmptySelection = false
        table.allowsMultipleSelection = false
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        table.focusRingType = .none
        table.dataSource = self
        table.delegate = self
        table.setAccessibilityLabel(String(localized: "Settings pages", bundle: .module))
        scroll.documentView = table
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.scrollerStyle = .overlay
        addPinnedSubview(scroll, insets: NSDirectionalEdgeInsets(top: SettingsMetrics.titleStripHeight, leading: 0, bottom: 0, trailing: 0))
        applyTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: ThemedControls.paletteDidChange, object: nil)
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    /// Moves the selection; `notify: false` for a programmatic move the controller already knows about.
    public func select(_ index: Int, notify: Bool) {
        guard index >= 0, index < pages.count else { return }
        suppress = !notify
        table.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        suppress = false
    }

    /// The selected page's index (-1 before the first selection).
    public var selectedIndex: Int { table.selectedRow }

    /// The rows' spoken titles, for the harnesses.
    public var rowLabelsForTesting: [String] {
        (0..<pages.count).compactMap {
            (table.view(atColumn: 0, row: $0, makeIfNecessary: true) as? SettingsSidebarCell)?.label.stringValue
        }
    }

    public func numberOfRows(in tableView: NSTableView) -> Int { pages.count }

    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        tableView.reusableView { SettingsSidebarRowView() }
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell =
            tableView.makeView(withIdentifier: SettingsSidebarCell.identifier, owner: self) as? SettingsSidebarCell ?? SettingsSidebarCell()
        cell.configure(title: pages[row].title, symbol: pages[row].symbol)
        cell.setSelected(tableView.selectedRow == row)
        return cell
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        for row in 0..<pages.count {
            (table.view(atColumn: 0, row: row, makeIfNecessary: false) as? SettingsSidebarCell)?.setSelected(row == table.selectedRow)
        }
        if !suppress, table.selectedRow >= 0 { onSelect?(table.selectedRow) }
    }

    @objc private func themeChanged() { applyTheme() }

    /// Re-tints the list for the current theme, keeping the selected row.
    public func applyTheme() {
        styleLayer(background: ThemedControls.palette.sidebarBackground)
        table.backgroundColor = ThemedControls.palette.sidebarBackground
        // Reloading clears the selection, and a table that disallows an empty one then picks
        // row 0 and reports it as a click — picking a theme on Appearance would jump to General.
        // Keep the row, and say nothing while the reload runs.
        let selected = table.selectedRow
        suppress = true
        table.reloadData()
        if selected >= 0 { table.selectRowIndexes(IndexSet(integer: selected), byExtendingSelection: false) }
        suppress = false
        if table.selectedRow >= 0 {
            for row in 0..<pages.count {
                (table.view(atColumn: 0, row: row, makeIfNecessary: false) as? SettingsSidebarCell)?.setSelected(row == table.selectedRow)
            }
        }
    }
}
