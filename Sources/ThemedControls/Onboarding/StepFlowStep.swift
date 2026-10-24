//
//  StepFlowStep.swift
//  ThemedControls
//
//  One page of a step-by-step guide: its symbol, its heading and the controller whose view fills it.
//
//  Created by David Sherlock on 10/24/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// One page of a ``StepFlowView``: an SF Symbol on an accent tile, a heading, a line under it, and
/// the controller whose view fills the page — ``SettingsSectionsView`` rows, so a guide's rows are
/// the very rows of the app's Settings, or any view of its own.
public struct StepFlowStep {
    /// The page's heading.
    public let title: String
    /// The line under the heading: what this step decides, and where to change it later.
    public let subtitle: String
    /// The controller whose view fills the page; held by the flow for its life.
    public let content: NSViewController
    /// The SF Symbol beside the heading, or nil for none.
    public let symbol: String?

    /// A page headed `title` over `subtitle` beside `symbol`, filled by `content`'s view.
    public init(title: String, subtitle: String, symbol: String? = nil, content: NSViewController) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.content = content
    }
}
