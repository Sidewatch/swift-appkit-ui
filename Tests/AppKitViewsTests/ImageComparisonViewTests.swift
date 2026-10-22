//
//  ImageComparisonViewTests.swift
//  AppKitViewsTests
//
//  The comparison view drawn and read back: which version shows where, in each mode; the
//  divider under the pointer and the keys; pictures enlarged without smoothing.
//
//  Created by David Sherlock on 10/22/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import XCTest
@testable import AppKitViews

@MainActor final class ImageComparisonViewTests: XCTestCase {
    private let colors = ImageComparisonColors(
        background: .black, checkerLight: .white, checkerDark: .lightGray, divider: .yellow, change: .green, caption: .white)

    /// A `width`×`height` picture of one colour, with `marks` (x, y from the top-left) in another.
    private func picture(_ width: Int, _ height: Int, _ c: (UInt8, UInt8, UInt8), marks: [(Int, Int, (UInt8, UInt8, UInt8))] = [])
        -> CGImage
    {
        var bytes = [UInt8](repeating: 255, count: width * height * 4)
        for i in 0..<(width * height) { (bytes[i * 4], bytes[i * 4 + 1], bytes[i * 4 + 2]) = c }
        for (x, y, m) in marks { let i = (y * width + x) * 4; (bytes[i], bytes[i + 1], bytes[i + 2]) = m }
        return CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: CGDataProvider(data: Data(bytes) as CFData)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    }

    /// A grayscale mask, white at `marks`.
    private func mask(_ width: Int, _ height: Int, marks: [(Int, Int)]) -> CGImage {
        var bytes = [UInt8](repeating: 0, count: width * height)
        for (x, y) in marks { bytes[y * width + x] = 255 }
        return CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue), provider: CGDataProvider(data: Data(bytes) as CFData)!,
            decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    }

    private func view(_ mode: ImageComparisonMode, old: CGImage?, new: CGImage?) -> ImageComparisonView {
        let v = ImageComparisonView(colors: colors)
        v.frame = NSRect(x: 0, y: 0, width: 424, height: 224)  // a 400×200 area inside the 12-point inset
        v.mode = mode
        v.oldImage = old
        v.newImage = new
        return v
    }

    /// The view drawn at one pixel a point; the colour at (x, y) from the top-left.
    private func colour(_ v: NSView, _ x: Int, _ y: Int) -> NSColor {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(v.bounds.width), pixelsHigh: Int(v.bounds.height), bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = v.bounds.size
        v.cacheDisplay(in: v.bounds, to: rep)
        return rep.colorAt(x: x, y: y)!.usingColorSpace(.sRGB)!
    }
    private func isRed(_ c: NSColor) -> Bool { c.redComponent > 0.8 && c.greenComponent < 0.2 && c.blueComponent < 0.2 }
    private func isBlue(_ c: NSColor) -> Bool { c.blueComponent > 0.8 && c.redComponent < 0.2 && c.greenComponent < 0.2 }
    private func isGreen(_ c: NSColor) -> Bool { c.greenComponent > 0.8 && c.redComponent < 0.2 && c.blueComponent < 0.2 }

    // MARK: - Geometry

    func testAPictureFitsItsSpaceWithItsShapeKeptAndCentred() {
        let area = CGRect(x: 0, y: 0, width: 400, height: 200)
        XCTAssertEqual(ImageComparisonLayout.fit(CGSize(width: 100, height: 100), in: area), CGRect(x: 100, y: 0, width: 200, height: 200))
        XCTAssertEqual(ImageComparisonLayout.fit(CGSize(width: 800, height: 100), in: area), CGRect(x: 0, y: 75, width: 400, height: 50))
        XCTAssertEqual(
            ImageComparisonLayout.fit(CGSize(width: 4, height: 4), in: area), CGRect(x: 168, y: 68, width: 64, height: 64),
            "a small picture is enlarged at most 16 times")
        XCTAssertEqual(ImageComparisonLayout.fit(.zero, in: area), .zero)
    }

    func testSideBySideSplitsTheSpaceInTwo() {
        let panes = ImageComparisonLayout.panes(in: CGRect(x: 0, y: 0, width: 416, height: 100), gap: 16)
        XCTAssertEqual(panes.old, CGRect(x: 0, y: 0, width: 200, height: 100))
        XCTAssertEqual(panes.new, CGRect(x: 216, y: 0, width: 200, height: 100))
    }

    func testTheDividerFollowsThePointerWithinThePicture() {
        let frame = CGRect(x: 100, y: 0, width: 200, height: 100)
        XCTAssertEqual(ImageComparisonLayout.swipeFraction(atX: 150, in: frame), 0.25)
        XCTAssertEqual(ImageComparisonLayout.swipeFraction(atX: 20, in: frame), 0)
        XCTAssertEqual(ImageComparisonLayout.swipeFraction(atX: 900, in: frame), 1)
    }

    // MARK: - Drawn

    func testSideBySideShowsBeforeLeftAndAfterRight() {
        let v = view(.sideBySide, old: picture(10, 10, (255, 0, 0)), new: picture(10, 10, (0, 0, 255)))
        let panes = v.sideBySidePanes
        XCTAssertTrue(isRed(colour(v, Int(panes.old.midX), Int(panes.old.midY))))
        XCTAssertTrue(isBlue(colour(v, Int(panes.new.midX), Int(panes.new.midY))))
    }

    func testSwipingShowsBeforeLeftOfTheDividerAndAfterRightOfIt() {
        let v = view(.swipe, old: picture(40, 20, (255, 0, 0)), new: picture(40, 20, (0, 0, 255)))
        let frame = v.swipeFrame
        XCTAssertEqual(frame, CGRect(x: 12, y: 12, width: 400, height: 200))
        XCTAssertTrue(isRed(colour(v, 100, 112)))
        XCTAssertTrue(isBlue(colour(v, 320, 112)))
        v.setSwipePosition(0.9)
        XCTAssertTrue(isRed(colour(v, 320, 112)), "moved right, more of before shows")
    }

    func testTheDividerFollowsADragAndTheArrowKeys() throws {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 424, height: 224), styleMask: [.titled], backing: .buffered, defer: false)
        let v = view(.swipe, old: picture(40, 20, (255, 0, 0)), new: picture(40, 20, (0, 0, 255)))
        window.contentView = v
        var reported: CGFloat?
        v.onSwipe = { reported = $0 }
        // Window coordinates run up from the bottom; the view is flipped and fills the window.
        let down = try XCTUnwrap(
            NSEvent.mouseEvent(
                with: .leftMouseDown, location: NSPoint(x: 112, y: 112), modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber,
                context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
        v.mouseDown(with: down)
        XCTAssertEqual(v.swipePosition, 0.25, accuracy: 0.001)
        XCTAssertEqual(reported ?? -1, 0.25, accuracy: 0.001)
        let right = try XCTUnwrap(
            NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber, context: nil,
                characters: String(Character(UnicodeScalar(NSRightArrowFunctionKey)!)),
                charactersIgnoringModifiers: String(Character(UnicodeScalar(NSRightArrowFunctionKey)!)), isARepeat: false, keyCode: 124))
        v.keyDown(with: right)
        XCTAssertEqual(v.swipePosition, 0.30, accuracy: 0.001)
        v.mode = .sideBySide
        v.mouseDown(with: down)
        XCTAssertEqual(v.swipePosition, 0.30, accuracy: 0.001, "side by side, a click moves nothing")
    }

    func testChangesAreDrawnInTheChangeColourOverTheDimmedAfter() {
        // A 40×20 picture fills the 400×200 area at 10 points a pixel; pixel (10, 0) changed.
        let v = view(.changes, old: picture(40, 20, (0, 0, 255)), new: picture(40, 20, (0, 0, 255)))
        v.changeMask = mask(40, 20, marks: [(10, 0)])
        XCTAssertTrue(isGreen(colour(v, 12 + 105, 12 + 5)), "the changed pixel, in the change colour")
        let unchanged = colour(v, 12 + 350, 12 + 150)
        XCTAssertFalse(isGreen(unchanged))
        // Dimmed over the checkerboard, full blue washes out: red and green rise from 0, blue still leads.
        XCTAssertGreaterThan(unchanged.redComponent, 0.4, "the after picture is dimmed: \(unchanged)")
        XCTAssertGreaterThan(unchanged.blueComponent, unchanged.redComponent + 0.2, "but still there: \(unchanged)")
    }

    func testEnlargedPixelsStaySquare() {
        // A 2×1 picture, red then blue, enlarged 16 times: the last column of the red pixel is red.
        let v = view(.changes, old: nil, new: picture(2, 1, (255, 0, 0), marks: [(1, 0, (0, 0, 255))]))
        v.newImage = picture(2, 1, (255, 0, 0), marks: [(1, 0, (0, 0, 255))])
        let frame = ImageComparisonLayout.fit(CGSize(width: 2, height: 1), in: v.bounds.insetBy(dx: 12, dy: 12))
        XCTAssertEqual(frame.width, 32)
        // The red pixel's last column matches its centre: smoothing would mix blue in at the edge.
        let centre = colour(v, Int(frame.minX) + 8, Int(frame.midY))
        let edge = colour(v, Int(frame.minX) + 15, Int(frame.midY))
        XCTAssertEqual(edge.redComponent, centre.redComponent, accuracy: 0.01, "\(edge) against \(centre)")
        XCTAssertEqual(edge.blueComponent, centre.blueComponent, accuracy: 0.01, "\(edge) against \(centre)")
    }
}
