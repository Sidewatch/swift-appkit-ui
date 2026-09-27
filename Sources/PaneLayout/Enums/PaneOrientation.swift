//
//  PaneOrientation.swift
//  PaneLayout
//
//  Which way an axis lays its members out.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Which way an axis lays its members out: horizontal puts them left to right, vertical
/// stacks them top to bottom.
public enum PaneOrientation: Sendable {
    case horizontal, vertical
}
