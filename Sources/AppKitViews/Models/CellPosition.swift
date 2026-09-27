//
//  CellPosition.swift
//  AppKitViews
//
//  Which cell of a table is being edited: a row and which field of it.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Which cell of a table is being edited, and therefore where Tab would take the keyboard next.
///
/// It is a POSITION rather than a view on purpose: committing an edit often rewrites the model
/// and rebuilds the rows, so a stored view reference would point at something already gone.
public struct CellPosition: Equatable, Hashable, Sendable {
    /// The table row, in the order the table is currently showing it.
    public let row: Int
    /// Which field of that row, by the field's `tag`.
    public let tag: Int

    public init(row: Int, tag: Int) {
        self.row = row
        self.tag = tag
    }
}
