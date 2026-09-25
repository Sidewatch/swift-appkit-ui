//
//  ZoomKeyDirection.swift
//  AppKitViews
//
//  Which way a zoom key points.
//
//  Created by David Sherlock on 9/26/26.
//

import AppKit

/// Which way a zoom key points: ⌘= / ⌘+ in, ⌘- out, ⌘0 back to actual size.
///
/// One map for every surface that answers those keys, so a view that zooms and a view that
/// merely passes them on agree about what they mean.
public enum ZoomKeyDirection: Sendable {
    case `in`, out, actual
}

extension ZoomKeyDirection {
    /// Reads a key press, the Zoom menu's convention. `nil` for any other key, so a caller can
    /// hand the event straight on.
    public init?(keyChars: String?) {
        switch keyChars {
        case "=", "+": self = .in
        case "-":      self = .out
        case "0":      self = .actual
        default:       return nil
        }
    }
}
