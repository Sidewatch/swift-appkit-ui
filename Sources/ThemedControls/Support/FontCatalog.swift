//
//  FontCatalog.swift
//  ThemedControls
//
//  The font choices Settings offers, and the one place a stored choice is turned back into an
//  `NSFont`.
//
//  Created by David Sherlock on 9/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import AppKitViews

/// The font choices Settings offers, and the one place a stored choice becomes an `NSFont`.
///
/// **The split between the two halves is load-bearing.** Enumeration walks a family's members
/// through `NSFontManager` — fine in Settings, ruinous in a render path (349 ms in a sampled
/// gutter stall). So a pane resolves a chosen weight to its PostScript name ONCE, when picked, and
/// ``font(family:postScriptName:size:)`` only does an exact `NSFont(name:)`, `nonisolated`.
public enum FontCatalog {

    /// One selectable weight within a family: the face name shown in the popup ("SemiBold"), the
    /// PostScript name that actually resolves it, and AppKit's 0…15 weight for ordering.
    public struct Face: Equatable, Sendable {
        /// The face name a popup shows ("SemiBold").
        public let name: String
        /// The PostScript name that actually resolves it; empty for a system weight.
        public let postScriptName: String
        /// AppKit's 0…15 weight, for ordering.
        public let weight: Int
        /// Creates a face record.
        public init(name: String, postScriptName: String, weight: Int) {
            self.name = name
            self.postScriptName = postScriptName
            self.weight = weight
        }
    }

    /// The name the weight popup shows when a family is left at whatever its default face is.
    /// Stored as `nil`, never as this string.
    public static let defaultFaceTitle = "Regular"

    // MARK: - Enumeration (Settings only — walks font members, never call while rendering)

    /// Monospaced font families offered for the editor and terminal. Proportional families are
    /// excluded: a terminal grid assumes one advance width, and the column arithmetic misaligns
    /// with anything else.
    public static func monospacedFamilies() -> [String] {
        let manager = NSFontManager.shared
        return manager.availableFontFamilies.filter { family in
            guard let members = manager.availableMembers(ofFontFamily: family) else { return false }
            return members.contains { member in
                guard member.count > 3, let traits = member[3] as? UInt else { return false }
                return traits & NSFontTraitMask.fixedPitchFontMask.rawValue != 0
            }
        }
    }

    /// The upright weights `family` offers, lightest first; `nil` means the system monospaced font.
    ///
    /// Italics are excluded on purpose: the weight is the *base*, and syntax highlighting derives
    /// italic and bold from it at render time (Light still gets Light Italic comments). A family
    /// with one upright face (Monaco) returns one entry, which a pane uses to hide the popup.
    public static func faces(inFamily family: String?) -> [Face] {
        guard let family else {
            return systemFaceNames.enumerated().map { index, name in
                // No PostScript name exists for these — the system monospaced font is reached
                // through `monospacedSystemFont(ofSize:weight:)`, not by name, and
                // `font(family:postScriptName:size:)` routes a nil family there. The weight is
                // the list index rather than AppKit's 0…15 scale for the same reason: it only
                // has to sort, and the list is already in order.
                Face(name: name, postScriptName: "", weight: index)
            }
        }
        guard let members = NSFontManager.shared.availableMembers(ofFontFamily: family) else { return [] }
        var seen = Set<String>()
        return members.compactMap { member -> Face? in
            guard member.count > 3,
                  let postScript = member[0] as? String,
                  let name = member[1] as? String,
                  let weight = member[2] as? Int,
                  let traits = member[3] as? UInt,
                  traits & NSFontTraitMask.italicFontMask.rawValue == 0,
                  seen.insert(name).inserted
            else { return nil }
            return Face(name: name, postScriptName: postScript, weight: weight)
        }
        .sorted { $0.weight < $1.weight }
    }

    /// The PostScript name for a chosen weight, persisted beside the family for
    /// ``font(family:postScriptName:size:)``. `nil` for the default face, a face the family lacks
    /// (left over after switching family), or the system font — each of which the render path
    /// handles by falling back.
    public static func postScriptName(inFamily family: String?, face: String?) -> String? {
        guard let family, let face else { return nil }
        return faces(inFamily: family).first { $0.name == face }?.postScriptName
    }

    // MARK: - Resolution (the render path — no enumeration, safe off-main)

    /// Resolves a persisted choice to a font, falling back rather than failing at every step.
    ///
    /// The order is deliberate: a stale PostScript name keeps the FAMILY and drops to its default
    /// face, since the family is the bigger part of the choice; only a missing family falls back to
    /// the system font. `face` names a system weight and is read only when `family` is nil.
    public nonisolated static func font(family: String?, postScriptName: String?, face: String? = nil,
                                size: CGFloat) -> NSFont {
        guard let family else {
            return .mono(size, weight: systemWeight(named: face))
        }
        // Exact, and cheap: no member walk, which is the whole reason the name was resolved when
        // the user picked it rather than here.
        if let postScriptName, let font = NSFont(name: postScriptName, size: size) { return font }
        // Family → descriptor, not NSFont(name:), which wants a PostScript face name and returns
        // nil for most valid family choices.
        if let font = NSFont(descriptor: NSFontDescriptor(fontAttributes: [.family: family]), size: size) {
            return font
        }
        return .mono(size)
    }

    // MARK: - The system monospaced font

    /// The weights of the system monospaced font, which has no family in `availableFontFamilies`
    /// to enumerate — `.SF NS Mono` is hidden, and is reached through
    /// `NSFont.monospacedSystemFont(ofSize:weight:)` rather than by name.
    ///
    /// Apple's own spelling ("Semibold", one word) is kept even though the bundled JetBrains Mono
    /// spells that weight "SemiBold": each family is labelled the way it labels itself, so the
    /// popup matches what the font is called everywhere else.
    private static let systemFaceNames = ["Light", "Regular", "Medium", "Semibold", "Bold"]

    /// A table, not stored state — render paths read this off the main actor, and a static
    /// array of `NSFont.Weight` would be shared mutable state to the concurrency checker.
    nonisolated private static func systemWeight(named name: String?) -> NSFont.Weight {
        switch name {
        case "Light":    return .light
        case "Medium":   return .medium
        case "Semibold": return .semibold
        case "Bold":     return .bold
        default:         return .regular
        }
    }
}
