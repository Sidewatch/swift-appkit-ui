//
//  NSFont+Mono.swift
//  AppKitViews
//
//  Monospaced system fonts by size.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSFont {
    /// The monospaced system font.
    static func mono(_ size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        .monospacedSystemFont(ofSize: size, weight: weight)
    }

    /// The system font with monospaced digits, for numbers that must not jitter as they change.
    static func monoDigits(_ size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        .monospacedDigitSystemFont(ofSize: size, weight: weight)
    }
}
