//
//  EdgeDragDirection.swift
//  AppKitViews
//
//  Which way dragging a pane's edge makes the pane bigger.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Which way dragging a pane's edge makes the pane bigger, in window coordinates (y runs upward): a
/// pane under its top edge grows `up`, one above its bottom edge grows `down`, one beside its leading
/// edge grows `left`, one beside its trailing edge grows `right`.
public enum EdgeDragDirection: Sendable {
    case up, down, left, right
}
