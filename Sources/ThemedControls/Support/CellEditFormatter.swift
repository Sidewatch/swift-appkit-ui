//
//  CellEditFormatter.swift
//  ThemedControls
//
//  A field that READS as one thing and EDITS as another — quotes, a trailing colon, a mask.
//
//  Created by David Sherlock on 9/25/26.
//

import Foundation

/// The decoration a table or outline cell wears, kept out of what you type over (25 Sep 2026).
///
/// A cell often shows more than its value: a string reads as `"nginx"`, a tree key as `image:`,
/// a secret as `••••••••`. The text you type over must be the bare value — and swapping the
/// field's `stringValue` inside `controlTextDidBeginEditing` does **not** reliably reach the
/// field editor, which AppKit has already loaded from the cell. A shipped build quoted a tree
/// value again on every double-click for exactly that reason, writing to a file nobody had
/// edited. A `Formatter` is the mechanism AppKit honours: `string(for:)` is what the row draws,
/// `editingString(for:)` is what the editor loads, and the typed text comes back through the
/// field's `objectValue` untouched.
///
/// ```swift
/// field.formatter = CellEditFormatter(prefix: "\"", suffix: "\"")   // reads "nginx", edits nginx
/// field.objectValue = value
/// …
/// let typed = field.objectValue as? String                          // never `stringValue`
/// ```
///
/// A cell never rejects what you type: what a value MEANS is the format's decision, made where
/// the edit is applied, not here.
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
    public nonisolated required init?(coder: NSCoder) { nil }

    /// What the row shows.
    public nonisolated override func string(for obj: Any?) -> String? {
        guard let text = obj as? String else { return nil }
        return substitute ?? (prefix + text + suffix)
    }

    /// What the field editor loads when editing begins — the bare value, always.
    public nonisolated override func editingString(for obj: Any?) -> String? { obj as? String }

    /// The typed text, kept exactly as written.
    public nonisolated override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
                                                    for string: String,
                                                    errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        obj?.pointee = string as NSString
        return true
    }
}
