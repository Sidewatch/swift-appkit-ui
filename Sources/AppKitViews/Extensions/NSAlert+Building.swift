//
//  NSAlert+Building.swift
//  AppKitViews
//
//  Alerts built and answered in one call.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSAlert {
    /// An alert with its text, style and buttons, first button first. The button titled `cancel`
    /// (the app's own word for "Cancel" unless given) answers Escape.
    convenience init(
        message: String, information: String = "", style: NSAlert.Style = .warning,
        buttons: [String] = [], cancel: String = NSAlert.cancelTitle
    ) {
        self.init()
        messageText = message
        informativeText = information
        alertStyle = style
        for title in buttons {
            let button = addButton(withTitle: title)
            // AppKit gives Escape only to a button titled with ITS translation of "Cancel", which
            // an app's own translation may word differently; the app's word decides here.
            if title == cancel { button.keyEquivalent = "\u{1b}" }
        }
    }

    /// The app's own word for "Cancel" (its main-bundle string table), in the current language.
    static var cancelTitle: String {
        Bundle.main.localizedString(forKey: "Cancel", value: "Cancel", table: nil)
    }

    /// Runs the alert modally and answers whether its FIRST button was chosen.
    func runConfirmed() -> Bool {
        runModal() == .alertFirstButtonReturn
    }

    /// Shows the alert as a sheet on `window`, or modally with no window, and hands the
    /// completion whether the first button was chosen.
    func beginConfirmed(on window: NSWindow?, _ completion: @escaping @MainActor (Bool) -> Void) {
        guard let window else { completion(runConfirmed()); return }
        beginSheetModal(for: window) { response in
            MainActor.assumeIsolated { completion(response == .alertFirstButtonReturn) }
        }
    }
}
