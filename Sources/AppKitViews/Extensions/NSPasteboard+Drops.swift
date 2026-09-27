//
//  NSPasteboard+Drops.swift
//  AppKitViews
//
//  The drop flow: dragged or pasted local files, raw image bytes, file promises and links,
//  turned into shell-ready path text.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import FoundationExtensions

/// The shared "hand the agent a file" pasteboard flow: turns dragged or pasted
/// local files, raw image bytes, file promises, and links into shell-ready path
/// text. Used by the terminal (drag-drop AND ⌘V image paste) and by the Agent
/// Composer's input drop target, so both surfaces behave identically.
extension NSPasteboard {

    /// Every pasteboard type the drop flow can consume — what a drop target
    /// should pass to `registerForDraggedTypes`.
    public static var dropReadableTypes: [NSPasteboard.PasteboardType] {
        var types: [NSPasteboard.PasteboardType] = [.fileURL, .URL, .png, .tiff]
        types += NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) }
        return types
    }

    /// True when the pasteboard holds anything `readDroppedFiles` can consume:
    /// URLs, file promises, or raw image bytes.
    public var containsDroppableContent: Bool {
        canReadObject(forClasses: [NSURL.self, NSFilePromiseReceiver.self])
            || data(forType: .png) != nil || data(forType: .tiff) != nil
    }

    /// True when a ⌘V can't be serviced as text but CAN as a file drop: no plain
    /// string, but file URLs or raw image bytes are present (a screenshot taken
    /// to the clipboard with ⌃⇧⌘4 is the canonical case).
    public var containsFilesButNoText: Bool {
        guard string(forType: .string) == nil else { return false }
        return canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
            || data(forType: .png) != nil || data(forType: .tiff) != nil
    }

    /// Resolves the pasteboard into ready-to-insert text and hands it to `insert`
    /// on the main queue: local files become shell-quoted paths (trailing space);
    /// raw image bytes are saved into the drops folder first; file promises are
    /// received into the drops folder and delivered as they land (so `insert` may
    /// run more than once, asynchronously); plain links insert their URL strings.
    /// Every branch hands over EVERY item — Finder writes one pasteboard item per
    /// dragged file, and a drop that keeps only the first reads as "the agent got
    /// the wrong image".
    /// Returns `false` when the pasteboard holds nothing this flow can use.
    /// `insert` may run MORE THAN ONCE and asynchronously: a file promise is received off the
    /// main thread and delivered as it lands, so a drop of three promised files calls back three
    /// times. Every call arrives on the MAIN ACTOR, which is why the closure is declared
    /// `@MainActor` rather than `@Sendable` — a caller inserting into a view can then capture
    /// and mutate its own state normally, instead of having to make a thread-safe sink for a
    /// callback that was always going to arrive on main anyway.
    @discardableResult
    @MainActor
    public func readDroppedFiles(insert: @escaping @MainActor (String) -> Void) -> Bool {
        let urls = (readObjects(forClasses: [NSURL.self]) as? [URL]) ?? []

        // 1. Local files: hand over their quoted paths directly.
        let files = urls.filter(\.isFileURL)
        if !files.isEmpty { insert(Self.shellQuoted(files)); return true }

        // 2. File promises (Safari/Photos/Mail): receive into the drops folder first.
        if let receivers = readObjects(forClasses: [NSFilePromiseReceiver.self]) as? [NSFilePromiseReceiver],
           !receivers.isEmpty {
            guard let dir = Self.dropsDirectory(unique: true) else { return false }
            for receiver in receivers {
                receiver.receivePromisedFiles(atDestination: dir, options: [:], operationQueue: Self.promiseQueue) { url, error in
                    guard error == nil else { return }
                    let text = Self.shellQuoted([url])
                    Task { @MainActor in insert(text) }
                }
            }
            return true
        }

        // 3. Raw image bytes with no backing file (screenshots, images copied out
        //    of a browser): save each as PNG, then hand over the saved paths. Walked
        //    PER ITEM — `data(forType:)` on the pasteboard is the FIRST item's data, so
        //    a multi-image drop used to save one file and drop the rest silently.
        let saved = (pasteboardItems ?? []).compactMap { item -> URL? in
            let png = item.data(forType: .png) ?? item.data(forType: .tiff).flatMap {
                NSBitmapImageRep(data: $0)?.representation(using: .png, properties: [:])
            }
            return png.flatMap { Self.saveDrop(data: $0, ext: "png") }
        }
        if !saved.isEmpty { insert(Self.shellQuoted(saved)); return true }

        // 4. Plain links: their URL strings, every one of them.
        if !urls.isEmpty { insert(urls.map(\.absoluteString).joined(separator: " ") + " "); return true }
        return false
    }

    // MARK: - Drops-folder plumbing

    /// File promises resolve off the main thread; one shared queue serves them all.
    private static let promiseQueue = OperationQueue()

    /// The files' shell-quoted paths (space-separated, trailing space), escaping
    /// single quotes so paths with spaces/apostrophes stay one argument.
    nonisolated private static func shellQuoted(_ files: [URL]) -> String {
        files.map { $0.path.shellQuoted }.joined(separator: " ") + " "
    }

    /// Writes raw dropped data (e.g. an image off the clipboard) into the drops
    /// folder and returns the file URL.
    nonisolated private static func saveDrop(data: Data, ext: String) -> URL? {
        guard let dir = dropsDirectory(unique: false) else { return nil }
        let url = dir.appendingPathComponent("dropped-\(UUID().uuidString.prefix(8)).\(ext)")
        return (try? data.write(to: url)) != nil ? url : nil
    }

    /// The folder name under the temporary directory that saved drops land in. A host sets this
    /// once at launch so its files are recognisable in `/tmp`, and so two apps using this package
    /// cannot write into each other's.
    nonisolated(unsafe) public static var dropsFolderName = "AppKitViewsDrops"

    /// `<tmp>/<dropsFolderName>[/<uuid>]` — created on demand; `unique` adds a fresh subfolder so
    /// same-named promised files from separate drops cannot collide.
    nonisolated private static func dropsDirectory(unique: Bool) -> URL? {
        var dir = FileManager.default.temporaryDirectory.appendingPathComponent(dropsFolderName)
        if unique { dir.appendPathComponent(UUID().uuidString.prefix(8).description) }
        return (try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)) != nil ? dir : nil
    }
}
