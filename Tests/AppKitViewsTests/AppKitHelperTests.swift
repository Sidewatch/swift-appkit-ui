//
//  AppKitHelperTests.swift
//  AppKitViewsTests
//
//  The one-call AppKit helpers: pinning, labels, symbols, fonts, layers, alerts, the
//  pasteboard and menu items — each measured on the object it built, not on its arguments.
//
//  Created by David Sherlock on 9/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
@testable import AppKitViews

@MainActor final class AppKitHelperTests: XCTestCase {
    private func laidOut(_ host: NSView) {
        host.frame = NSRect(x: 0, y: 0, width: 200, height: 100)
        host.layoutSubtreeIfNeeded()
    }

    func testAddPinnedSubviewInsetsEveryEdgeInward() {
        let host = NSView(), child = NSView()
        let cs = host.addPinnedSubview(child, insets: .init(top: 5, leading: 10, bottom: 15, trailing: 20))
        laidOut(host)
        XCTAssertFalse(child.translatesAutoresizingMaskIntoConstraints)
        XCTAssertEqual(cs.count, 4)
        XCTAssertTrue(cs.allSatisfy(\.isActive))
        XCTAssertEqual(child.frame, NSRect(x: 10, y: 15, width: 170, height: 80), "unflipped: bottom inset lifts minY")
    }

    func testPinEdgesHonoursTheChosenEdgesAndPriority() {
        let host = NSView(), child = NSView()
        host.addSubviewsForAutoLayout(child)
        let cs = child.pinEdges(to: host, edges: [.leading, .trailing], priority: .defaultHigh)
        XCTAssertEqual(cs.count, 2)
        XCTAssertTrue(cs.allSatisfy { $0.priority == .defaultHigh })
        child.pinSize(height: 30)
        child.pinCenter(to: host, x: false)
        laidOut(host)
        XCTAssertEqual(child.frame, NSRect(x: 0, y: 35, width: 200, height: 30))
    }

    func testEdgeConstraintsAreReturnedInactive() {
        let host = NSView(), child = NSView()
        host.addSubview(child)
        let cs = child.edgeConstraints(to: host)
        XCTAssertEqual(cs.count, 4)
        XCTAssertFalse(cs.contains(where: \.isActive))
        XCTAssertFalse(child.translatesAutoresizingMaskIntoConstraints)
    }

    func testPinningToALayoutGuide() {
        let host = NSView(), child = NSView(), guide = NSLayoutGuide()
        host.addLayoutGuide(guide)
        NSLayoutConstraint.activate([guide.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 50),
                                     guide.trailingAnchor.constraint(equalTo: host.trailingAnchor),
                                     guide.topAnchor.constraint(equalTo: host.topAnchor),
                                     guide.bottomAnchor.constraint(equalTo: host.bottomAnchor)])
        host.addSubviewsForAutoLayout(child)
        child.pinEdges(to: guide)
        laidOut(host)
        XCTAssertEqual(child.frame.minX, 50)
        XCTAssertEqual(child.frame.width, 150)
    }

    func testLabelAppliesOnlyWhatItIsGiven() {
        let plain = NSTextField.label("a"), stock = NSTextField(labelWithString: "a")
        XCTAssertEqual(plain.font, stock.font)
        XCTAssertEqual(plain.textColor, stock.textColor)
        XCTAssertEqual(plain.lineBreakMode, stock.lineBreakMode)
        let styled = NSTextField.label("b", font: .mono(11), color: .red, lineBreak: .byTruncatingMiddle, alignment: .right)
        XCTAssertFalse(styled.isEditable)
        XCTAssertEqual(styled.font, .monospacedSystemFont(ofSize: 11, weight: .regular))
        XCTAssertEqual(styled.textColor, .red)
        XCTAssertEqual(styled.lineBreakMode, .byTruncatingMiddle)
        XCTAssertEqual(styled.alignment, .right)
    }

    func testSymbolSizesByPointSizeAndMenuSymbolIsFourteenPoints() throws {
        let small = try XCTUnwrap(NSImage.symbol("star", pointSize: 8))
        let large = try XCTUnwrap(NSImage.symbol("star", pointSize: 32, weight: .bold))
        XCTAssertLessThan(small.size.width, large.size.width)
        XCTAssertNil(NSImage.symbol("not.a.symbol.name"))
        XCTAssertEqual(NSImage.menuSymbol("star")?.size, NSSize(width: 14, height: 14))
    }

    func testMonoFonts() {
        XCTAssertEqual(NSFont.mono(12, weight: .bold), .monospacedSystemFont(ofSize: 12, weight: .bold))
        XCTAssertEqual(NSFont.monoDigits(12), .monospacedDigitSystemFont(ofSize: 12, weight: .regular))
    }

    func testStyleLayerSetsOnlyWhatItIsGiven() throws {
        let v = NSView()
        v.styleLayer(background: .red, cornerRadius: 6, borderWidth: 1)
        let layer = try XCTUnwrap(v.layer)
        XCTAssertTrue(v.wantsLayer)
        XCTAssertEqual(layer.cornerRadius, 6)
        XCTAssertEqual(layer.borderWidth, 1)
        XCTAssertEqual(layer.backgroundColor, NSColor.red.cgColor)
        v.styleLayer(cornerRadius: 2)
        XCTAssertEqual(layer.backgroundColor, NSColor.red.cgColor, "an omitted argument leaves the property alone")
        XCTAssertEqual(layer.cornerRadius, 2)
    }

    func testAlertInitializerBuildsTextStyleAndButtonsInOrder() {
        let a = NSAlert(message: "M", information: "I", style: .critical, buttons: ["Go", "Cancel"])
        XCTAssertEqual(a.messageText, "M")
        XCTAssertEqual(a.informativeText, "I")
        XCTAssertEqual(a.alertStyle, .critical)
        XCTAssertEqual(a.buttons.map(\.title), ["Go", "Cancel"])
        XCTAssertEqual(NSAlert(message: "x").alertStyle, NSAlert().alertStyle, "the default style is AppKit's own")
    }

    func testPasteboardCopyReplacesTheContents() {
        let pb = NSPasteboard(name: .init("appkitviews-test-\(UUID())"))
        defer { pb.releaseGlobally() }
        pb.setString("old", forType: .string)
        pb.setString("stale", forType: .init("public.utf8-plain-text-other"))
        XCTAssertTrue(pb.copy("new"))
        XCTAssertEqual(pb.string(forType: .string), "new")
        XCTAssertFalse(pb.types?.contains(.init("public.utf8-plain-text-other")) ?? true,
                       "the other representations went with the old contents")
    }

    func testMenuAddItemTargetsGlyphsAndCarriesItsObject() {
        final class Target: NSObject { @objc func act() {} }
        let t = Target(), menu = NSMenu()
        let item = menu.addItem("Do", action: #selector(Target.act), target: t, symbol: "star", key: "d", represented: 7)
        XCTAssertTrue(menu.items.first === item)
        XCTAssertTrue(item.target === t)
        XCTAssertEqual(item.action, #selector(Target.act))
        XCTAssertEqual(item.keyEquivalent, "d")
        XCTAssertEqual(item.representedObject as? Int, 7)
        XCTAssertEqual(item.image?.size, NSSize(width: 14, height: 14))
        XCTAssertNil(menu.addItem("Bare", action: #selector(Target.act), target: t, symbol: "no.such.glyph").image)
    }

    func testBlendAndTint() throws {
        func red(_ f: CGFloat) throws -> CGFloat {
            try XCTUnwrap(NSColor.black.blended(f, toward: .white).usingColorSpace(.sRGB)).redComponent
        }
        XCTAssertEqual(try red(0), 0, accuracy: 0.001, "no blend is the colour itself")
        XCTAssertEqual(try red(1), 1, accuracy: 0.001, "a full blend is the other colour")
        XCTAssertTrue(try red(0.25) < red(0.5) && red(0.5) < red(0.75), "a larger fraction moves further")
        let tinted = try XCTUnwrap(NSImage.symbol("star", pointSize: 20)).tinted(.red)
        XCTAssertFalse(tinted.isTemplate)
    }

    func testSystemTextIntelligenceOff() {
        let tv = NSTextView()
        tv.isAutomaticSpellingCorrectionEnabled = true
        tv.disableSystemTextIntelligence()
        XCTAssertFalse(tv.isAutomaticSpellingCorrectionEnabled)
        XCTAssertFalse(tv.isAutomaticQuoteSubstitutionEnabled)
        XCTAssertFalse(tv.isAutomaticTextCompletionEnabled)
        let w = NSWindow()
        XCTAssertTrue(FieldEditorPolicy.editor(for: w) === FieldEditorPolicy.editor(for: w), "one editor per window")
        XCTAssertTrue(FieldEditorPolicy.editor(for: w).isFieldEditor)
    }

    func testVisibleToUserNeedsAShownWindowAnUnhiddenChainAndSomeArea() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 200), styleMask: [.borderless],
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 200))
        let child = NSView(frame: NSRect(x: 10, y: 10, width: 50, height: 50))
        parent.addSubview(child)
        window.contentView = parent
        XCTAssertFalse(child.isVisibleToUser, "a window never shown")
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        XCTAssertTrue(child.isVisibleToUser)
        parent.isHidden = true
        XCTAssertFalse(child.isVisibleToUser, "a hidden ancestor hides it")
        parent.isHidden = false
        // A scroll view clips: a row scrolled out of sight is not visible, though nothing is hidden.
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        let doc = FlippedDocument(frame: NSRect(x: 0, y: 0, width: 100, height: 1000))
        let row = NSView(frame: NSRect(x: 0, y: 900, width: 100, height: 50))
        doc.addSubview(row)
        scroll.documentView = doc
        parent.addSubview(scroll)
        doc.scroll(.zero)
        XCTAssertFalse(row.isVisibleToUser, "scrolled out of sight")
        doc.scroll(NSPoint(x: 0, y: 880))
        XCTAssertTrue(row.isVisibleToUser, "scrolled into view")
    }
}

private final class FlippedDocument: NSView { override var isFlipped: Bool { true } }
