//
//  CellEditFormatter.swift
//  ThemedControls
//
//  A field that READS as one thing and EDITS as another — quotes, a trailing colon, a mask.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The decoration a table or outline cell wears (`"nginx"`, `image:`, `••••••••`), kept out of
/// what you type over.
///
/// Must be a `Formatter`: swapping `stringValue` in `controlTextDidBeginEditing` does **not** reach
/// the field editor AppKit has already loaded, so the decoration gets edited into the value.
/// `string(for:)` is what the row draws, `editingString(for:)` what the editor loads; read the
/// edit from `objectValue`, never `stringValue`. It never rejects input.
public final class CellEditFormatter: Formatter, @unchecked Sendable {
    private let prefix: String
    private let suffix: String
    /// Shown INSTEAD of the value when set — a mask over a secret. Editing still loads the value.
    private let substitute: String?

    /// A decoration wrapped around the value: quotes, a trailing colon, brackets.
    public nonisolated init(prefix: String = "", suffix: String = "") {
        self.prefix = prefix
        self.suffix = suffix
        self.substitute = nil
        super.init()
    }

    /// A fixed stand-in shown in place of the value, such as a row of bullets over a secret.
    public nonisolated init(substitute: String) {
        self.prefix = ""
        self.suffix = ""
        self.substitute = substitute
        super.init()
    }

    public nonisolated override init() {
        prefix = ""; suffix = ""; substitute = nil
        super.init()
    }
    /// Not archivable; always nil.
    public nonisolated required init?(coder: NSCoder) { nil }

    /// What the row shows.
    public nonisolated override func string(for obj: Any?) -> String? {
        guard let text = obj as? String else { return nil }
        return substitute ?? (prefix + text + suffix)
    }

    /// What the field editor loads when editing begins — the bare value, always.
    public nonisolated override func editingString(for obj: Any?) -> String? { obj as? String }

    /// The typed text, kept exactly as written.
    public nonisolated override func getObjectValue(
        _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
        for string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        obj?.pointee = string as NSString
        return true
    }
}
