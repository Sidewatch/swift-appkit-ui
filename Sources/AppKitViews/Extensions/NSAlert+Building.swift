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
    /// An alert with its text, style and buttons, first button first.
    convenience init(message: String, information: String = "", style: NSAlert.Style = .warning,
                     buttons: [String] = []) {
        self.init()
        messageText = message
        informativeText = information
        alertStyle = style
        for title in buttons { addButton(withTitle: title) }
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
