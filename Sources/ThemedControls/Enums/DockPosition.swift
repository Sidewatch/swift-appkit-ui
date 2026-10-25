//
//  DockPosition.swift
//  ThemedControls
//
//  Where a docked panel sits beside a window's main content.
//
//  Created by David Sherlock on 10/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

/// Where a docked panel (a terminal, a console) sits against the main content, in reading order.
public enum DockPosition: CaseIterable, Sendable {
    /// Before the content, after any sidebar.
    case leading
    /// Under the content.
    case bottom
    /// After the content.
    case trailing
}
