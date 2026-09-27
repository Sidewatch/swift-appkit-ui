//
//  NSView+Layer.swift
//  AppKitViews
//
//  Giving a view a styled backing layer in one call.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

public extension NSView {
    /// Makes the view layer-backed and styles the layer. Nil arguments leave that property as
    /// it is. Colours are resolved now, so call again when the appearance or theme changes.
    func styleLayer(
        background: NSColor? = nil, cornerRadius: CGFloat? = nil,
        borderColor: NSColor? = nil, borderWidth: CGFloat? = nil,
        masksToBounds: Bool? = nil
    ) {
        wantsLayer = true
        guard let layer else { return }
        if let background { layer.backgroundColor = background.cgColor }
        if let cornerRadius { layer.cornerRadius = cornerRadius }
        if let borderColor { layer.borderColor = borderColor.cgColor }
        if let borderWidth { layer.borderWidth = borderWidth }
        if let masksToBounds { layer.masksToBounds = masksToBounds }
    }
}
