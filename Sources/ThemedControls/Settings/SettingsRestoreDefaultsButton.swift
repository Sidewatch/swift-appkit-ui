//
//  SettingsRestoreDefaultsButton.swift
//  ThemedControls
//
//  A page's Restore Defaults button: asks in a sheet, then puts the page's settings back.
//
//  Created by David Sherlock on 10/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// A page's Restore Defaults button, under its last card. A click asks in a sheet on the page's
/// window; Restore Defaults there restores the page and re-reads its controls, Cancel does nothing.
public final class SettingsRestoreDefaultsButton: ThemedPillButton {
    /// The page whose settings the button restores.
    public private(set) weak var pane: (any SettingsDefaultsRestoring)?

    /// A button that restores `pane`.
    public convenience init(pane: any SettingsDefaultsRestoring) {
        self.init(title: String(localized: "Restore Defaults", bundle: .module), target: nil, action: nil)
        self.pane = pane
        target = self
        action = #selector(askToRestore)
    }

    /// The question the sheet asks; Escape answers Cancel.
    static func makeAlert() -> NSAlert {
        let cancel = String(localized: "Cancel", bundle: .module, comment: "Settings: dismiss the Restore Defaults question")
        return NSAlert(
            message: String(
                localized: "Restore this page's settings to their defaults?", bundle: .module,
                comment: "Settings: the Restore Defaults confirmation's question"),
            information: String(
                localized: "The other pages keep theirs.", bundle: .module, comment: "Settings: the Restore Defaults confirmation's detail"),
            buttons: [String(localized: "Restore Defaults", bundle: .module), cancel], cancel: cancel)
    }

    @objc private func askToRestore() {
        guard let window, let pane else { return }
        Self.makeAlert().beginSheetModal(for: window) { [weak pane] response in
            guard response == .alertFirstButtonReturn, let pane else { return }
            pane.restoreDefaults()
            pane.syncFromSettings()
        }
    }
}
