//
//  SettingsWordListView.swift
//  ThemedControls
//
//  An editable list of short strings: a fixed-height table, a +/− bar, and optional Restore
//  Defaults.
//
//  Created by David Sherlock on 7/26/26.
//

import AppKit

/// An editable list of short strings: a fixed-height table, a +/− bar, and optional
/// Restore Defaults.
///
/// A list rather than a comma-separated text field. One word per row is how the platform does
/// this, and it removes the questions a delimited string forces on the reader — whether spaces
/// matter, what happens to an empty entry, whether a word may contain a comma.
///
/// The inline-editing behaviour here is subtle and was learned the hard way in the skipped-
/// directories list; the comments on each piece say what breaks without it.
/// Vends TWO views, and they must go into two separate rows — the list spanning the card edge to
/// edge with no inset or padding, the button bar with the card's standard inset. Putting both in
/// one zero-padding row jams the buttons against the card's edges.
///
/// ```swift
/// SettingsRowView(spanning: list.listView, inset: 0, padding: 0),
/// SettingsRowView(spanning: list.buttonBar),
/// ```
public final class SettingsWordListView: NSObject, NSTableViewDataSource, NSTableViewDelegate,
                                  NSTextFieldDelegate {

    /// Called with the canonical list — trimmed, de-duplicated, sorted — whenever it changes.
    public var onChange: (([String]) -> Void)?

    /// Supply to offer a Restore Defaults button; leave nil to omit it entirely.
    public var defaultWords: [String]? {
        didSet { restoreButton.isHidden = defaultWords == nil; updateButtonState() }
    }

    /// The scrolling list. Goes in a row with `inset: 0, padding: 0`.
    public let listView = NSScrollView()
    /// The +/− and Restore Defaults bar. Goes in its own row, at the card's standard inset.
    public let buttonBar = NSView()

    private let table = NSTableView()
    private let addRemoveControl = ThemedSegmentBar(labels: ["Add", "Remove"], symbols: ["plus", "minus"])   // themed +/−, momentary
    private let restoreButton = ThemedPillButton(title: "Restore Defaults", target: nil, action: nil)
    private let columnID = NSUserInterfaceItemIdentifier("WordListItem")

    /// The list as displayed — sorted, and the only place a not-yet-committed new row exists.
    private var words: [String] = []

    /// The row editor in flight, if any. Held to tell a live edit from one that has already
    /// ended: the end-editing notification arrives for both.
    private weak var editingField: NSTextField?

    /// The placeholder shown on a blank row, e.g. "word".
    private let noun: String

    public init(noun: String = "word") {
        self.noun = noun
        super.init()
        buildUI()
    }


    // MARK: - Layout

    private func buildUI() {
        let column = NSTableColumn(identifier: columnID)
        column.resizingMask = .autoresizingMask
        table.addTableColumn(column)
        table.headerView = nil
        table.style = .inset
        table.rowHeight = 22
        table.backgroundColor = .clear
        table.usesAlternatingRowBackgroundColors = false
        table.allowsMultipleSelection = true
        table.dataSource = self
        table.delegate = self
        table.target = self
        table.doubleAction = #selector(editSelectedWord)

        // The list's height is fixed and its contents are not: a card that grew to fit every word
        // would own the pane.
        listView.documentView = table
        listView.hasVerticalScroller = true
        listView.autohidesScrollers = true
        // The card is the list's border and background; a bordered scroll view inside it would
        // draw a second box a hairline in from the first.
        listView.borderType = .noBorder
        listView.drawsBackground = false
        listView.translatesAutoresizingMaskIntoConstraints = false
        listView.heightAnchor.constraint(equalToConstant: SettingsMetrics.listHeight).isActive = true

        addRemoveControl.isMomentary = true
        addRemoveControl.symbolsOnly = true
        addRemoveControl.barHeight = 22
        addRemoveControl.setAccessibilityLabel("Add or remove words")
        addRemoveControl.target = self
        addRemoveControl.action = #selector(addRemoveClicked)

        restoreButton.target = self
        restoreButton.action = #selector(restoreDefaults)
        restoreButton.isHidden = true
        restoreButton.translatesAutoresizingMaskIntoConstraints = false

        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        buttonBar.addSubview(addRemoveControl)
        buttonBar.addSubview(restoreButton)
        NSLayoutConstraint.activate([
            // A fixed bar height centers both controls without either one's natural height
            // deciding the row's.
            buttonBar.heightAnchor.constraint(equalToConstant: 24),
            addRemoveControl.leadingAnchor.constraint(equalTo: buttonBar.leadingAnchor),
            addRemoveControl.centerYAnchor.constraint(equalTo: buttonBar.centerYAnchor),
            restoreButton.trailingAnchor.constraint(equalTo: buttonBar.trailingAnchor),
            restoreButton.centerYAnchor.constraint(equalTo: buttonBar.centerYAnchor),
            restoreButton.leadingAnchor.constraint(greaterThanOrEqualTo: addRemoveControl.trailingAnchor,
                                                   constant: 12),
        ])
    }

    // MARK: - Table

    public func numberOfRows(in tableView: NSTableView) -> Int { words.count }

    /// Vends one editable cell. An `NSTableCellView` rather than a bare text field for its
    /// `textField` outlet: it is what editing focuses, and what the table recolors to stay
    /// legible on a selected row.
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = (tableView.makeView(withIdentifier: columnID, owner: self) as? NSTableCellView)
            ?? makeWordCell()
        cell.textField?.stringValue = words[row]
        return cell
    }

    /// Builds a cell: a flat, editable field filling the row.
    private func makeWordCell() -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = columnID

        // A label is a text field that starts flat and inert — exactly the rename-in-place look,
        // once it is allowed to edit.
        let field = NSTextField(labelWithString: "")
        field.font = .systemFont(ofSize: 12)
        field.isEditable = true
        field.isSelectable = true
        field.placeholderString = noun
        field.lineBreakMode = .byTruncatingTail
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false

        cell.addSubview(field)
        cell.textField = field
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
            field.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }

    public func tableViewSelectionDidChange(_ notification: Notification) { updateButtonState() }

    /// Double-click renames, matching every other name list on the platform.
    @objc private func editSelectedWord() {
        guard table.selectedRow >= 0 else { return }
        beginEditing(row: table.selectedRow)
    }

    /// Drops `row` into inline editing, scrolling it into view first — a row below the fold has
    /// no cell view to focus.
    ///
    /// The cell's text field is focused directly rather than through `editColumn(_:row:with:select:)`,
    /// which by its own contract only *attempts* to make the cell view first responder and does
    /// nothing if it declines. A silent no-op there would leave a just-added row un-editable and
    /// then swept away by the next redisplay, so + would look broken.
    private func beginEditing(row: Int) {
        table.scrollRowToVisible(row)
        guard let cell = table.view(atColumn: 0, row: row, makeIfNecessary: true) as? NSTableCellView,
              let field = cell.textField else { return }
        table.window?.makeFirstResponder(field)
    }

    // MARK: - Add / remove

    @objc private func addRemoveClicked(_ sender: ThemedSegmentBar) {
        if sender.clickedSegment == 0 { addWord() } else { removeSelectedWords() }
    }

    /// Appends a blank row and drops straight into editing it. The blank lives here only —
    /// nothing reaches the caller until the edit commits, and an abandoned row is dropped by the
    /// blank filter. Appended rather than sorted into place because it has no text to sort by
    /// yet; the redisplay after the commit is what files it.
    private func addWord() {
        commitRowEditing()
        words.append("")
        table.reloadData()
        let row = words.count - 1
        table.selectRowIndexes([row], byExtendingSelection: false)
        beginEditing(row: row)
    }

    /// Removes every selected word. Any in-flight edit is discarded first: the row being edited
    /// can be one of the selected ones, and its editor would otherwise commit a word straight
    /// back onto the list it was taken off.
    private func removeSelectedWords() {
        endRowEditing()
        let selected = table.selectedRowIndexes
        guard !selected.isEmpty else { return }
        words = words.enumerated().filter { !selected.contains($0.offset) }.map(\.element)
        commit()
    }

    /// Restores the supplied defaults, discarding any half-typed row with them — the user asked
    /// for the defaults, not the defaults plus what they were typing.
    @objc private func restoreDefaults() {
        guard let defaultWords else { return }
        endRowEditing()
        words = canonical(defaultWords)
        table.reloadData()
        updateButtonState()
        onChange?(words)
    }

    /// Remove is only live with a selection; Restore Defaults dims once the list already is the
    /// shipped one.
    private func updateButtonState() {
        addRemoveControl.setEnabled(!table.selectedRowIndexes.isEmpty, forSegment: 1)
        if let defaultWords { restoreButton.isEnabled = words != canonical(defaultWords) }
    }

    // MARK: - Editing

    public func controlTextDidBeginEditing(_ obj: Notification) {
        editingField = obj.object as? NSTextField
    }

    /// Commits a row on Return, Tab or focus loss. A field that is no longer the tracked editor
    /// was aborted by `endRowEditing`, and must not write back the text that was discarded.
    public func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField, field === editingField else { return }
        editingField = nil
        let row = table.row(for: field)
        guard row >= 0, row < words.count else { return }
        words[row] = field.stringValue
        commit()
    }

    /// Commits any in-flight row edit through the normal end-editing path, so a word typed just
    /// before clicking + is kept rather than thrown away.
    ///
    /// Clicking a button does not end an edit by itself — AppKit buttons refuse first responder,
    /// so the field editor survives the click. Handing the table first responder forces it to
    /// resign, which fires the end-editing notification synchronously.
    private func commitRowEditing() {
        guard editingField != nil else { return }
        table.window?.makeFirstResponder(table)
    }

    /// Discards any in-flight row edit. Clearing `editingField` first is what makes the
    /// end-editing notification a no-op for it.
    private func endRowEditing() {
        guard let field = editingField else { return }
        editingField = nil
        _ = field.abortEditing()
        // abortEditing() ends the edit but leaves the field first responder; the table has to
        // take it back, or the next keystroke lands in a dead editor.
        table.window?.makeFirstResponder(table)
    }

    /// Trimmed, blanks dropped, de-duplicated case-insensitively, sorted.
    private func canonical(_ input: [String]) -> [String] {
        var seen = Set<String>()
        return input
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// Publishes the canonical list and re-displays it.
    private func commit() {
        words = canonical(words)
        onChange?(words)
        // Deferred because this can run from inside the field editor's end-editing notification,
        // where reloading tears down a cell view the control is still unwinding through. Skipped
        // outright if another row went into edit meanwhile (clicking + twice does exactly that):
        // reloading under a live editor strands it on a row index that may no longer exist, and
        // that edit's own commit re-displays anyway.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.editingField == nil else { return }
            self.table.reloadData()
            self.updateButtonState()
        }
    }
}
