//
//  PaneSplitDirection.swift
//  PaneLayout
//
//  Where a split puts the new pane, and which axis that implies.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Where a split puts the new pane relative to the one being split.
///
/// The direction carries both decisions a split needs, so a caller never has to work out the
/// axis and the insertion side separately and get one of them the wrong way round.
public enum PaneSplitDirection: Sendable {
    case up, down, left, right

    /// Left and right lay members side by side; up and down stack them.
    public var orientation: PaneOrientation { (self == .left || self == .right) ? .horizontal : .vertical }
    /// Left and up put the NEW pane before the existing one; right and down after.
    public var placesNewFirst: Bool { self == .left || self == .up }
}
