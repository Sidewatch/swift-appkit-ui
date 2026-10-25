//
//  SettingsDefaultsRestoring.swift
//  ThemedControls
//
//  A settings page that can put its own settings back to their defaults.
//
//  Created by David Sherlock on 10/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// A settings page that can put its own settings back to their defaults. `buildPane` gives such a
/// page a Restore Defaults button under its last card; the button asks first, then calls
/// `restoreDefaults()` and `syncFromSettings()`.
public protocol SettingsDefaultsRestoring: SettingsPane {
    /// Writes every setting this page shows back to its default, through the same setters its
    /// controls use, so whatever a change sets in motion runs as it would for a click.
    func restoreDefaults()
}
