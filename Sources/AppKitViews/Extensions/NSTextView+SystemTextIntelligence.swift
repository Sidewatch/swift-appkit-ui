//
//  NSTextView+SystemTextIntelligence.swift
//  AppKitViews
//
//  Turning off Writing Tools, autocorrect and the other system text services.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSTextView {
    /// Suppresses Writing Tools on this view: its context menu and Edit menu entry.
    func disableWritingTools() {
        if #available(macOS 15.2, *) { writingToolsBehavior = .none }
    }

    /// Writing Tools, autocorrect, smart substitutions, spelling and grammar marks, data and
    /// link detection and inline predictive text, all off. Idempotent.
    func disableSystemTextIntelligence() {
        disableWritingTools()
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        isAutomaticTextCompletionEnabled = false   // inline predictive text rides this
        isContinuousSpellCheckingEnabled = false
        isGrammarCheckingEnabled = false
        isAutomaticDataDetectionEnabled = false
        isAutomaticLinkDetectionEnabled = false
    }
}

public extension NSTextField {
    /// The two switches that live on the FIELD, not its editor: inline predictive text and
    /// Writing Tools. AppKit copies both onto the field editor when editing begins, so a
    /// window editor with them off is overruled by a field with them on. Every text field calls
    /// this once; ``FieldEditorPolicy`` covers the rest.
    func disableSystemTextIntelligence() {
        isAutomaticTextCompletionEnabled = false
        if #available(macOS 15.2, *) { allowsWritingTools = false }
    }
}

/// One configured field editor per window. AppKit expects the same instance back for a window
/// and never retains it, so the table holds it, keyed weakly by window.
@MainActor
public enum FieldEditorPolicy {
    private static let editors = NSMapTable<NSWindow, NSTextView>.weakToStrongObjects()

    /// The field editor `window` should lend its text fields, with every system text service off.
    public static func editor(for window: NSWindow) -> NSTextView {
        if let existing = editors.object(forKey: window) { return existing }
        let editor = NSTextView()
        editor.isFieldEditor = true
        editor.disableSystemTextIntelligence()
        editors.setObject(editor, forKey: window)
        return editor
    }
}
