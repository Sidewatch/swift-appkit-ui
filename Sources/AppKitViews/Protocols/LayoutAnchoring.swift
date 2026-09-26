//
//  LayoutAnchoring.swift
//  AppKitViews
//
//  Anything constraints can pin to: a view or a layout guide.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// Anything that exposes the eight layout anchors, so one pinning helper serves a view and a
/// layout guide alike.
@MainActor
public protocol LayoutAnchoring {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
}

extension NSView: LayoutAnchoring {}
extension NSLayoutGuide: LayoutAnchoring {}
