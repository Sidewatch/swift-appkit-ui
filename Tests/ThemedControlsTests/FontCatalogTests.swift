//
//  FontCatalogTests.swift
//  ThemedControlsTests
//
//  Enumeration for the settings pane, exact resolution for the render path, fallbacks between.
//
//  Created by David Sherlock on 9/26/26.
//

import XCTest
import AppKit
@testable import ThemedControls

@MainActor final class FontCatalogTests: XCTestCase {

    // MARK: - Enumeration

    func testMonospacedFamiliesAreOfferedAndProportionalOnesAreNot() {
        let families = FontCatalog.monospacedFamilies()
        XCTAssertFalse(families.isEmpty)
        XCTAssertTrue(families.contains("Menlo"), "a monospaced family ships on every Mac")
        for proportional in ["Helvetica", "Times New Roman", "Arial"] {
            XCTAssertFalse(families.contains(proportional),
                           "\(proportional) is proportional; a terminal grid assumes one advance width")
        }
    }

    /// The counts are measured, and they are what the panes use to decide whether the weight row
    /// is worth showing at all.
    func testAFamilyWithOneUprightFaceIsDistinguishableFromOneWithSeveral() {
        XCTAssertEqual(FontCatalog.faces(inFamily: "Monaco").count, 1, "a one-item popup is furniture")
        XCTAssertGreaterThanOrEqual(FontCatalog.faces(inFamily: "Menlo").count, 2, "Regular and Bold at least")
    }

    /// Italic is a TRAIT highlighting derives from the base weight, so offering it as a starting
    /// point would give every rendered italic something to derive from twice.
    func testItalicFacesAreNotOffered() {
        let names = FontCatalog.faces(inFamily: "Menlo").map { $0.name.lowercased() }
        XCTAssertFalse(names.contains { $0.contains("italic") || $0.contains("oblique") },
                       "got \(names)")
    }

    func testFacesComeBackLightestFirst() {
        let weights = FontCatalog.faces(inFamily: "Menlo").map(\.weight)
        XCTAssertEqual(weights, weights.sorted())
    }

    func testEveryFaceOfARealFamilyResolves() {
        for face in FontCatalog.faces(inFamily: "Menlo") {
            XCTAssertFalse(face.postScriptName.isEmpty)
            XCTAssertNotNil(NSFont(name: face.postScriptName, size: 12), "\(face.name) did not resolve")
        }
    }

    func testAnUnknownFamilyHasNoFaces() {
        XCTAssertTrue(FontCatalog.faces(inFamily: "No Such Family At All").isEmpty)
    }

    /// The system monospaced font has no family to enumerate, so its weights are listed by hand
    /// and carry no PostScript name.
    func testTheSystemFontOffersWeightsWithNoPostScriptNames() {
        let faces = FontCatalog.faces(inFamily: nil)
        XCTAssertEqual(faces.map(\.name), ["Light", "Regular", "Medium", "Semibold", "Bold"])
        XCTAssertTrue(faces.allSatisfy { $0.postScriptName.isEmpty })
        XCTAssertEqual(faces.map(\.weight), [0, 1, 2, 3, 4], "the index only has to sort")
    }

    func testFaceNamesAreUnique() {
        let names = FontCatalog.faces(inFamily: "Menlo").map(\.name)
        XCTAssertEqual(names.count, Set(names).count)
    }

    // MARK: - Resolving a stored choice to a name

    func testAChosenWeightResolvesToItsPostScriptName() {
        guard let bold = FontCatalog.faces(inFamily: "Menlo").first(where: { $0.name == "Bold" }) else {
            return XCTFail("Menlo should offer Bold")
        }
        XCTAssertEqual(FontCatalog.postScriptName(inFamily: "Menlo", face: "Bold"), bold.postScriptName)
    }

    /// Switching family leaves behind a face name the new family does not have. That must read as
    /// "no stored name" rather than as an error.
    func testAFaceTheFamilyDoesNotHaveYieldsNil() {
        XCTAssertNil(FontCatalog.postScriptName(inFamily: "Menlo", face: "SemiBold"))
        XCTAssertNil(FontCatalog.postScriptName(inFamily: "Menlo", face: nil))
        XCTAssertNil(FontCatalog.postScriptName(inFamily: nil, face: "Bold"))
    }

    // MARK: - The render path

    func testAnExactPostScriptNameResolves() {
        guard let bold = FontCatalog.faces(inFamily: "Menlo").first(where: { $0.name == "Bold" }) else {
            return XCTFail("Menlo should offer Bold")
        }
        let font = FontCatalog.font(family: "Menlo", postScriptName: bold.postScriptName, size: 13)
        XCTAssertEqual(font.fontName, bold.postScriptName)
        XCTAssertEqual(font.pointSize, 13)
    }

    /// The fallback ORDER is the decision here: a stale PostScript name keeps the FAMILY, which
    /// is much the bigger part of what the user chose. Only a missing family falls all the way.
    func testAStalePostScriptNameKeepsTheFamily() {
        let font = FontCatalog.font(family: "Menlo", postScriptName: "NoSuchFace-Ultra", size: 13)
        XCTAssertEqual(font.familyName, "Menlo")
    }

    func testAMissingFamilyFallsBackToTheSystemMonospacedFont() {
        let font = FontCatalog.font(family: "No Such Family At All", postScriptName: nil, size: 13)
        XCTAssertEqual(font.pointSize, 13)
        XCTAssertTrue(font.isFixedPitch, "the fallback must still be monospaced")
    }

    func testANilFamilyIsTheSystemFontAtTheNamedWeight() {
        for (name, weight) in [("Light", NSFont.Weight.light), ("Medium", .medium),
                               ("Semibold", .semibold), ("Bold", .bold)] {
            let font = FontCatalog.font(family: nil, postScriptName: nil, face: name, size: 12)
            let expected = NSFont.monospacedSystemFont(ofSize: 12, weight: weight)
            XCTAssertEqual(font.fontName, expected.fontName, "weight \(name)")
        }
    }

    func testAnUnknownSystemWeightIsRegular() {
        let font = FontCatalog.font(family: nil, postScriptName: nil, face: "Ultralight", size: 12)
        XCTAssertEqual(font.fontName, NSFont.monospacedSystemFont(ofSize: 12, weight: .regular).fontName)
    }

    /// The render path runs once per line number while a gutter draws, so it must never walk a
    /// family's members. A thousand resolutions should be far under a frame.
    func testResolvingIsCheapEnoughForTheRenderPath() {
        guard let bold = FontCatalog.faces(inFamily: "Menlo").first(where: { $0.name == "Bold" }) else {
            return XCTFail("Menlo should offer Bold")
        }
        let start = Date()
        for _ in 0..<1_000 {
            _ = FontCatalog.font(family: "Menlo", postScriptName: bold.postScriptName, size: 13)
        }
        let elapsed = -start.timeIntervalSinceNow
        XCTAssertLessThan(elapsed, 0.1, "1,000 resolutions took \(elapsed)s; enumeration has crept in")
    }

    func testDefaultFaceTitleIsNeverStoredAsAFaceName() {
        XCTAssertEqual(FontCatalog.defaultFaceTitle, "Regular")
        XCTAssertNil(FontCatalog.postScriptName(inFamily: "Monaco", face: nil))
    }
}
