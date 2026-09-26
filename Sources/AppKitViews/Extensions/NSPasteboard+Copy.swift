//
//  NSPasteboard+Copy.swift
//  AppKitViews
//
//  Putting text on a pasteboard in one call.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSPasteboard {
    /// Replaces the pasteboard's contents with `text`; true when it was written.
    @discardableResult
    func copy(_ text: String) -> Bool {
        clearContents()
        return setString(text, forType: .string)
    }
}
