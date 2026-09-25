//
//  PathBarView.swift
//  ThemedControls
//
//  A path as clickable crumbs, each dropping its folder's contents, walkable from the keyboard.
//
//  Created by David Sherlock on 9/26/26.
//

import AppKit

/// A file's path as clickable crumbs, the way VS Code's breadcrumbs work: clicking a folder crumb
/// drops that folder's contents — subfolders as submenus filled only when opened, files as items,
/// the one on the current path ticked — and clicking the file crumb lists its siblings, so you can
/// move sideways without a sidebar.
///
/// **The host supplies the listing and the icons**, through `childrenProvider` and `iconProvider`.
/// The bar reads no directories itself, which keeps hidden files, ignore rules and sort order as
/// ONE decision made wherever the app already shows that tree, rather than a second one here that
/// drifts from it.
///
/// Keyboard: focusing the bar highlights a crumb, then ← and → move between them, ↓ / Space /
/// Return open the focused crumb's menu, and Escape hands focus back through `onDismissFocus`.
/// `keyAction(for:)` is the decision separated from the act, so it can be tested without popping a
/// menu — a menu's tracking loop would hold any test that opened one.
///
/// Subclass it to add accessory buttons. The bar lays its crumbs from the leading edge and leaves
/// the trailing edge alone.
open class PathBarView: NSView, NSMenuDelegate {

    // MARK: - Host hooks

    /// Lists a folder for a crumb's menu. Nothing is listed without this.
    public var childrenProvider: ((URL) -> [PathBarEntry])?
    /// The icon for a row. A folder falls back to the system folder symbol.
    public var iconProvider: ((PathBarEntry) -> NSImage?)?
    /// Items the host puts at the TOP of a folder's menu, above the listing and a separator.
    public var leadingItemsProvider: ((URL) -> [NSMenuItem])?
    /// The menu for a crumb that has NO url, by its index among such crumbs (0 = the first).
    /// Returning nil leaves that crumb as plain text.
    public var titleSegmentMenuProvider: ((Int) -> NSMenu?)?
    /// A file or folder was picked from a menu.
    public var onPick: ((URL) -> Void)?
    /// The bar gave up keyboard focus, by Escape or by a pick.
    public var onDismissFocus: (() -> Void)?

    /// Rows a folder menu lists before it says how many more there are. A menu longer than this
    /// is not a menu any more, and building it costs what it costs.
    public static let maxMenuEntries = 300

    /// The crumb the keyboard is on, or nil while the bar is not focused.
    public private(set) var focusedCrumb: Int?

    /// What a key does with the focus where it is — a decision, not an act.
    public enum KeyAction: Equatable, Sendable { case move(Int), open(Int), dismiss, unhandled }

    // MARK: - State

    /// The crumb strip. A subclass constrains it and puts its own controls beside it.
    public let crumbStack = NSStackView()
    private(set) public var segments: [PathSegment] = []
    /// Submenus waiting for their folder to be listed, keyed by menu identity — filled the first
    /// time AppKit asks, so a deep tree costs nothing until it is opened.
    private var pendingFolders: [ObjectIdentifier: URL] = [:]
    private var titleSegmentActions: [() -> Void] = []

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        crumbStack.orientation = .horizontal
        crumbStack.alignment = .centerY
        crumbStack.spacing = 2
        crumbStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        crumbStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        crumbStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(crumbStack)
    }
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }

    // MARK: - Crumbs

    /// Sets the crumbs. A no-op when they have not changed, so a status refresh that runs on a
    /// timer does not rebuild the strip and lose the focus under the keyboard.
    open func setPath(segments new: [PathSegment]) {
        guard new != segments else { return }
        segments = new
        for v in crumbStack.arrangedSubviews {
            crumbStack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        for (i, seg) in new.enumerated() {
            if i > 0 { crumbStack.addArrangedSubview(makeChevron()) }
            if seg.url != nil || titleSegmentMenuProvider != nil {
                crumbStack.addArrangedSubview(makeCrumbButton(seg, at: i))
            } else {
                crumbStack.addArrangedSubview(makeCrumbLabel(seg, at: i))
            }
        }
    }

    private func makeChevron() -> NSView {
        let chevron = NSTextField(labelWithString: "›")
        chevron.font = ThemedControls.palette.smallFont
        chevron.textColor = ThemedControls.palette.statusText
        chevron.setContentCompressionResistancePriority(.required, for: .horizontal)
        chevron.identifier = Self.chevronIdentifier
        return chevron
    }

    /// The crumbs give way LEFT-FIRST when the bar is too narrow: each is one point harder to
    /// squeeze than the one before it, so a long path loses its root before it loses the file
    /// name, which is the part you were looking at.
    private func squeezePriority(at index: Int) -> NSLayoutConstraint.Priority {
        NSLayoutConstraint.Priority(rawValue: 260 + Float(index))
    }

    private func makeCrumbButton(_ seg: PathSegment, at index: Int) -> NSButton {
        let b = NSButton(title: seg.title, target: self, action: #selector(crumbTapped(_:)))
        b.isBordered = false
        b.attributedTitle = crumbTitle(seg.title)
        b.lineBreakMode = .byTruncatingMiddle
        b.tag = index
        b.toolTip = seg.url?.path
        b.setAccessibilityLabel(seg.title)
        b.setContentCompressionResistancePriority(squeezePriority(at: index), for: .horizontal)
        b.setContentHuggingPriority(.required, for: .horizontal)
        return b
    }

    private func makeCrumbLabel(_ seg: PathSegment, at index: Int) -> NSTextField {
        let l = NSTextField(labelWithString: seg.title)
        l.font = ThemedControls.palette.smallFont
        l.textColor = ThemedControls.palette.statusText
        l.lineBreakMode = .byTruncatingMiddle
        l.tag = index
        l.setContentCompressionResistancePriority(squeezePriority(at: index), for: .horizontal)
        return l
    }

    /// A chevron is a label like any other, so it is marked rather than recognised by its text —
    /// a crumb legitimately called "›" would otherwise be skipped by every restyle.
    static let chevronIdentifier = NSUserInterfaceItemIdentifier("ThemedControls.PathBar.chevron")

    private func crumbTitle(_ title: String, focused: Bool = false) -> NSAttributedString {
        NSAttributedString(string: title, attributes: [
            .font: ThemedControls.palette.smallFont,
            .foregroundColor: focused ? ThemedControls.palette.accent : ThemedControls.palette.statusText,
        ])
    }

    /// Re-tints the crumbs: the focused one in the accent, the rest in the status tint. A
    /// subclass calls this from its own theme handling.
    open func restyleCrumbs() {
        for view in crumbStack.arrangedSubviews where view.identifier != Self.chevronIdentifier {
            guard let control = view as? NSControl else { continue }
            let focused = control.tag == focusedCrumb
            if let b = control as? NSButton {
                b.attributedTitle = crumbTitle(b.title, focused: focused)
            } else if let l = control as? NSTextField {
                l.font = ThemedControls.palette.smallFont
                l.textColor = focused ? ThemedControls.palette.accent : ThemedControls.palette.statusText
            }
        }
        for view in crumbStack.arrangedSubviews where view.identifier == Self.chevronIdentifier {
            (view as? NSTextField)?.textColor = ThemedControls.palette.statusText
            (view as? NSTextField)?.font = ThemedControls.palette.smallFont
        }
    }

    /// The crumb view at `index`, skipping the chevrons between them.
    public func crumbView(at index: Int) -> NSView? {
        crumbStack.arrangedSubviews.first {
            $0.identifier != Self.chevronIdentifier && ($0 as? NSControl)?.tag == index
        }
    }

    @objc private func crumbTapped(_ sender: NSButton) { openCrumbMenu(at: sender.tag) }

    /// Drops the crumb's menu under it.
    public func openCrumbMenu(at index: Int) {
        guard let menu = menu(forCrumbAt: index), let view = crumbView(at: index) else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: view.bounds.height + 4), in: view)
    }

    /// Focuses the last crumb and drops its menu.
    public func openLastCrumbMenu() {
        guard !segments.isEmpty else { return }
        let index = segments.count - 1
        focus(at: index)
        openCrumbMenu(at: index)
    }

    /// Focuses the last crumb with its menu closed, ready for ← → ↓.
    public func focusLastCrumb() {
        guard !segments.isEmpty else { return }
        focus(at: segments.count - 1)
    }

    // MARK: - Keyboard

    open override var acceptsFirstResponder: Bool { !segments.isEmpty }

    public func focus(at index: Int) {
        guard segments.indices.contains(index) else { return }
        focusedCrumb = index
        if window?.firstResponder !== self { window?.makeFirstResponder(self) }
        restyleCrumbs()
    }

    /// Focus leaves the bar: nothing highlighted, and the host takes the keyboard back.
    public func dismissFocus() {
        focusedCrumb = nil
        restyleCrumbs()
        onDismissFocus?()
    }

    open override func resignFirstResponder() -> Bool {
        focusedCrumb = nil
        restyleCrumbs()
        return true
    }

    /// What a key would do. Separated from doing it so it can be tested: opening a menu enters a
    /// tracking loop that would never return to a test.
    public func keyAction(for keyCode: UInt16) -> KeyAction {
        guard !segments.isEmpty else { return .unhandled }
        let at = focusedCrumb ?? (segments.count - 1)
        switch keyCode {
        case 123: return .move(max(0, at - 1))                        // ←
        case 124: return .move(min(segments.count - 1, at + 1))       // →
        case 125, 49, 36: return .open(at)                            // ↓ Space Return
        case 53: return .dismiss                                      // Escape
        default: return .unhandled
        }
    }

    open override func keyDown(with event: NSEvent) {
        switch keyAction(for: event.keyCode) {
        case .move(let i): focus(at: i)
        case .open(let i): focus(at: i); openCrumbMenu(at: i)
        case .dismiss: dismissFocus()
        case .unhandled: super.keyDown(with: event)
        }
    }

    // MARK: - Menus

    /// The menu a crumb drops: a folder crumb lists the folder, a file crumb lists its siblings
    /// with itself ticked, and a crumb with no URL asks `titleSegmentMenuProvider`. Nil when
    /// there is nothing to list.
    public func menu(forCrumbAt index: Int) -> NSMenu? {
        guard segments.indices.contains(index) else { return nil }
        guard let url = segments[index].url else {
            let level = index - segments.prefix { $0.url != nil }.count
            guard level >= 0 else { return nil }
            return titleSegmentMenuProvider?(level)
        }
        let isDir = segments[index].isDirectory
        let folder = isDir ? url : url.deletingLastPathComponent()
        // A folder crumb ticks the NEXT crumb, which is the path you are on through it; a file
        // crumb ticks itself among its siblings.
        let current = isDir ? (index + 1 < segments.count ? segments[index + 1].url : nil) : url
        let menu = NSMenu()
        menu.autoenablesItems = false
        fill(menu, folder: folder, highlighting: current)
        return menu
    }

    /// Fills a menu with a folder's rows. Public so a subclass can reuse it for a submenu.
    public func fill(_ menu: NSMenu, folder: URL, highlighting current: URL?) {
        if let leading = leadingItemsProvider?(folder), !leading.isEmpty {
            leading.forEach { menu.addItem($0) }
            menu.addItem(.separator())
        }
        let entries = childrenProvider?(folder) ?? []
        if entries.isEmpty {
            let empty = NSMenuItem(title: "Empty folder", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        }
        for e in entries.prefix(Self.maxMenuEntries) {
            // A FOLDER row has no action: it opens its submenu. Giving it one would make a click
            // on the way to a file open the folder instead.
            let item = NSMenuItem(title: e.title, action: e.isFolder ? nil : #selector(crumbItemPicked(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.representedObject = e.url
            item.image = iconProvider?(e)
                ?? (e.isFolder ? NSImage(systemSymbolName: "folder", accessibilityDescription: nil) : nil)
            if let current, e.url.standardizedFileURL.path == current.standardizedFileURL.path {
                item.state = .on
            }
            if e.isFolder {
                let sub = NSMenu(title: e.title)
                sub.autoenablesItems = false
                sub.delegate = self
                pendingFolders[ObjectIdentifier(sub)] = e.url
                item.submenu = sub
            }
            menu.addItem(item)
        }
        if entries.count > Self.maxMenuEntries {
            let more = NSMenuItem(title: "… \(entries.count - Self.maxMenuEntries) more", action: nil, keyEquivalent: "")
            more.isEnabled = false
            menu.addItem(more)
        }
    }

    /// A submenu is about to open: list its folder, once.
    open func menuNeedsUpdate(_ menu: NSMenu) {
        guard let folder = pendingFolders.removeValue(forKey: ObjectIdentifier(menu)) else { return }
        fill(menu, folder: folder, highlighting: nil)
    }

    @objc private func crumbItemPicked(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        onPick?(url)
        dismissFocus()
    }

    // MARK: - For tests and harnesses

    public var crumbTitlesForTesting: [String] { segments.map(\.title) }
    public var crumbURLsForTesting: [URL?] { segments.map(\.url) }
}
