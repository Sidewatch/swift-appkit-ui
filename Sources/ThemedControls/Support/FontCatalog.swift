//
//  FontCatalog.swift
//  ThemedControls
//
//  The font choices Settings offers, and the one place a stored choice is turned back into an
//  `NSFont`.
//
//  Created by David Sherlock on 9/26/26.
//

import AppKit

/// The font choices Settings offers, and the one place a stored choice is turned back into an
/// `NSFont`.
///
/// Two settings panes used to reach into a terminal type for this — the terminal answering the
/// editor's question — and each resolved its own font from a family descriptor.
/// That was fine while a family was the whole choice. Weight makes it two decisions that have to
/// agree about what a family *contains*, so enumeration and resolution live together here.
///
/// **The split between the two halves of this type is load-bearing.** Enumeration
/// (``monospacedFamilies()``, ``faces(inFamily:)``, ``postScriptName(inFamily:face:)``) goes
/// through `NSFontManager`, which walks a family's members — fine in Settings, ruinous anywhere
/// else: a host's editor-font accessor is called once per line number while a gutter draws, and resolving
/// a family through the font system there cost 349 ms in a sampled stall (3 Sep 2026). So the
/// panes resolve a chosen weight to its PostScript name ONCE, at the moment it is chosen, and the
/// render path ``font(family:postScriptName:size:)`` only ever does an exact
/// `NSFont(name:)` — no enumeration, and `nonisolated`, which it has to be to serve a render
/// path's background callers at all.
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
    ///
    /// Moved here from `TerminalSettings` (13 Sep 2026) when the editor's weight popup needed it
    /// too — it was never terminal-specific, it just lived where it was first needed.
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

    /// The upright weights `family` offers, lightest first. `nil` = the system monospaced font.
    ///
    /// Italic faces are filtered out on purpose, and their absence is not a gap. Weight here is
    /// the *base* the editor draws with; italic and bold are traits syntax highlighting derives
    /// from that base at render time (comments italic, keywords bold), so offering "Bold Italic"
    /// as a starting point would only give every rendered italic something to derive from twice.
    /// Picking Light still gets Light Italic comments, through the family's real Light Italic
    /// face — which is why the bundled JetBrains Mono ships an italic for every weight it offers.
    ///
    /// A family with one upright face returns one entry, which the panes use to hide the popup —
    /// Monaco and Andale Mono ship exactly one, and a one-item popup is furniture. (Menlo and
    /// PT Mono have two, Regular and Bold, so they DO get the row; the counts here are measured,
    /// and `--selftest-fonts` pins them.)
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

    /// The PostScript name for a chosen weight, to be persisted alongside the family and handed
    /// to ``font(family:postScriptName:size:)`` at render time.
    ///
    /// `nil` for the family's default face, for a face name the family doesn't have (which is
    /// what a switch from JetBrains Mono's "SemiBold" to Menlo leaves behind), and for the system
    /// font — each of which the render path already handles by falling back.
    public static func postScriptName(inFamily family: String?, face: String?) -> String? {
        guard let family, let face else { return nil }
        return faces(inFamily: family).first { $0.name == face }?.postScriptName
    }

    // MARK: - Resolution (the render path — no enumeration, safe off-main)

    /// Resolves a persisted choice to a font, falling back rather than failing at every step.
    ///
    /// The fallback order is deliberate: a PostScript name that no longer resolves keeps the
    /// FAMILY the user chose and drops to its default face, because the family is much the bigger
    /// part of the decision. Only a missing family falls all the way back to the system font.
    ///
    /// `postScriptName` is what the panes stored via ``postScriptName(inFamily:face:)``; `face` is
    /// consulted only when `family` is nil, where it names a system weight.
    public nonisolated static func font(family: String?, postScriptName: String?, face: String? = nil,
                                size: CGFloat) -> NSFont {
        guard let family else {
            return .monospacedSystemFont(ofSize: size, weight: systemWeight(named: face))
        }
        // Exact, and cheap: no member walk, which is the whole reason the name was resolved when
        // the user picked it rather than here.
        if let postScriptName, let font = NSFont(name: postScriptName, size: size) { return font }
        // Family → descriptor, not NSFont(name:), which wants a PostScript face name and returns
        // nil for most valid family choices.
        if let font = NSFont(descriptor: NSFontDescriptor(fontAttributes: [.family: family]), size: size) {
            return font
        }
        return .monospacedSystemFont(ofSize: size, weight: .regular)
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

    /// A table, not stored state — `Theme.editorFont` reads this off the main actor, and a static
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
