//
//  ImageComparisonMode.swift
//  AppKitViews
//
//  How an image comparison shows its two versions.
//
//  Created by David Sherlock on 10/22/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// How ``ImageComparisonView`` shows the two versions.
public enum ImageComparisonMode: Int, CaseIterable, Sendable {
    /// Before on the left, after on the right, each with its caption.
    case sideBySide
    /// Both in one frame, before left of a draggable divider and after right of it.
    case swipe
    /// The after version dimmed, the pixels that changed drawn in a colour over it.
    case changes
}
