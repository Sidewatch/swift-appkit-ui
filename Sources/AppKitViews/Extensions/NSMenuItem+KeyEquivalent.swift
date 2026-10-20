//
//  NSMenuItem+KeyEquivalent.swift
//  AppKitViews
//
//  A menu item's shortcut as people read it, and as a key for spotting two items with one shortcut.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// One shortcut, normalized: the key lower-cased and the Shift a capital letter implies folded into
/// the modifiers, so "O" with ⌘ and "o" with ⇧⌘ are the same combo and "o" with ⌘ is another.
public struct KeyCombo: Hashable, Sendable {
    /// The key, lower-cased (function keys stay as their private-use characters).
    public let key: String
    /// The device-independent modifiers, Shift included when the key implied it.
    public let modifiers: NSEvent.ModifierFlags.RawValue

    /// A combo.
    public init(key: String, modifiers: NSEvent.ModifierFlags) {
        self.key = key
        self.modifiers = modifiers.intersection(.deviceIndependentFlagsMask).rawValue
    }

    /// The combo as the menu bar draws it: `⌃⌥⇧⌘` in that order, then the key — arrows, Delete,
    /// Return, Tab, Escape and Space as their symbols, a function key as `F1`….
    public var display: String {
        let m = NSEvent.ModifierFlags(rawValue: modifiers)
        var s = ""
        if m.contains(.control) { s += "⌃" }
        if m.contains(.option) { s += "⌥" }
        if m.contains(.shift) { s += "⇧" }
        if m.contains(.command) { s += "⌘" }
        return s + Self.keyName(key)
    }

    /// The printable name of a lower-cased key equivalent.
    private static func keyName(_ key: String) -> String {
        guard let scalar = key.unicodeScalars.first, key.unicodeScalars.count == 1 else { return key.uppercased() }
        switch Int(scalar.value) {
        case NSUpArrowFunctionKey: return "↑"
        case NSDownArrowFunctionKey: return "↓"
        case NSLeftArrowFunctionKey: return "←"
        case NSRightArrowFunctionKey: return "→"
        case NSHomeFunctionKey: return "↖"
        case NSEndFunctionKey: return "↘"
        case NSPageUpFunctionKey: return "⇞"
        case NSPageDownFunctionKey: return "⇟"
        case NSDeleteFunctionKey: return "⌦"
        case 0x08, 0x7F: return "⌫"
        case 0x0D, 0x03: return "↩"
        case 0x09: return "⇥"
        case 0x1B: return "⎋"
        case 0x20: return "Space"
        case NSF1FunctionKey...NSF35FunctionKey: return "F\(Int(scalar.value) - NSF1FunctionKey + 1)"
        default: return key.uppercased()
        }
    }
}

public extension NSMenuItem {
    /// This item's shortcut normalized (``KeyCombo``), or nil when it has none — compare two items'
    /// combos to find a shortcut taken twice, which AppKit silently drops from one of them.
    var keyCombo: KeyCombo? {
        let raw = keyEquivalent
        guard !raw.isEmpty else { return nil }
        var modifiers = keyEquivalentModifierMask
        if raw.count == 1, let c = raw.first, c.isUppercase { modifiers.insert(.shift) }
        return KeyCombo(key: raw.lowercased(), modifiers: modifiers)
    }

    /// This item's shortcut as the menu bar draws it (``KeyCombo/display``), the Shift a capital key
    /// equivalent implies included (`"F"` with ⌘ is `⇧⌘F`). Empty when there is none.
    var keyEquivalentDisplay: String { keyCombo?.display ?? "" }
}
