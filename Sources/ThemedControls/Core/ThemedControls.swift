//
//  ThemedControls.swift
//  ThemedControls
//
//  Where the host installs its palette, and the notification that says it changed.
//
//  Created by David Sherlock on 9/5/26.
//

import AppKit

/// The registry the controls read from. Install a palette once at launch; post
/// `paletteDidChange` after every theme switch.
public enum ThemedControls {
    /// The current palette. `SystemPalette` until the host installs its own.
    public static var palette: any ControlPalette = SystemPalette()

    /// Posted by the host after the palette's colours changed; every control repaints.
    public static let paletteDidChange = Notification.Name("ThemedControls.paletteDidChange")

    /// Mirror of System Settings ▸ Accessibility ▸ Display ▸ Reduce Motion. Read once from the
    /// workspace; the host re-sets it on `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification`
    /// (a harness sets it directly). Controls that move — the switch's slide — snap when it is on.
    nonisolated(unsafe) public static var reduceMotion: Bool = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    /// Mirror of System Settings ▸ Accessibility ▸ Display ▸ Differentiate Without Colour, kept
    /// the same way as `reduceMotion`. A host whose surfaces say something by colour alone (a
    /// git-tinted tab title) adds a second signal while it is on.
    nonisolated(unsafe) public static var differentiateWithoutColor: Bool = NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor
}
