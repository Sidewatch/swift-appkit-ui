//
//  ThemedStepperFieldTests.swift
//  ThemedControlsTests
//
//  `ThemedStepperField`: the pop-up's height, a width for its widest value, clicks on the arrow
//  halves stepping within the range, typed numbers grouped or not, junk put back, ↑ in the field.
//
//  Created by David Sherlock on 10/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import ThemedControls

/// Tests for `ThemedStepperField`.
@MainActor
final class ThemedStepperFieldTests: XCTestCase {
    private final class Recorder: NSObject {
        var values: [Double] = []
        @objc func changed(_ sender: ThemedStepperField) { values.append(sender.doubleValue) }
    }

    private func makeField(_ recorder: Recorder) -> (ThemedStepperField, NSWindow) {
        let stepper = ThemedStepperField()
        stepper.formatter.locale = Locale(identifier: "en_US")
        stepper.minValue = 1000
        stepper.maxValue = 100_000
        stepper.increment = 500
        stepper.doubleValue = 10_000
        stepper.target = recorder
        stepper.action = #selector(Recorder.changed(_:))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 100), styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView?.addSubview(stepper)
        window.contentView?.layoutSubtreeIfNeeded()
        stepper.frame = NSRect(origin: NSPoint(x: 20, y: 20), size: stepper.intrinsicContentSize)
        stepper.layoutSubtreeIfNeeded()
        return (stepper, window)
    }

    /// A real click: the button-up is queued first, so the tracking loop ends after one step.
    private func click(_ stepper: ThemedStepperField, at point: NSPoint, in window: NSWindow) {
        let location = stepper.convert(point, to: nil)
        func event(_ type: NSEvent.EventType) -> NSEvent {
            NSEvent.mouseEvent(
                with: type, location: location, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
        }
        window.postEvent(event(.leftMouseUp), atStart: false)
        stepper.mouseDown(with: event(.leftMouseDown))
    }

    func testThePopUpsHeightAndRoomForTheWidestValue() {
        let (stepper, _) = makeField(Recorder())
        let popup = ThemedPopUpButton()
        popup.addItems(withTitles: ["Bottom"])
        XCTAssertEqual(stepper.intrinsicContentSize.height, 24, "the stock pop-up's height at 13 pt")
        XCTAssertEqual(stepper.intrinsicContentSize.height, popup.intrinsicContentSize.height)
        let widest = ("100,000" as NSString).size(withAttributes: [.font: NSFont.monoDigits(13)])
            .width
        XCTAssertGreaterThanOrEqual(stepper.intrinsicContentSize.width, widest + 12 + 11 + 14, "the maximum fits beside the arrows")
        XCTAssertEqual(stepper.displayedTextForTesting, "10,000", "the count is grouped")
    }

    func testInASettingsRowItIsThePopUpsHeightNotTheTextLines() {
        let stepper = ThemedStepperField()
        stepper.maxValue = 100_000
        stepper.doubleValue = 10_000
        let row = SettingsRowView("Lines to keep", control: stepper, footnote: "Every line costs memory.")
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 200), styleMask: [.titled], backing: .buffered, defer: false)
        let content = window.contentView!
        row.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            row.topAnchor.constraint(equalTo: content.topAnchor),
        ])
        content.layoutSubtreeIfNeeded()
        XCTAssertEqual(stepper.frame.height, 24, "laid out in a row, it is the pop-up's height")
        // A pane measured before it has a window (a settings page sizing itself) lays out alone.
        let alone = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 200))
        let other = ThemedStepperField()
        let detached = SettingsRowView("Lines to keep", control: other)
        detached.translatesAutoresizingMaskIntoConstraints = false
        alone.addSubview(detached)
        NSLayoutConstraint.activate([
            detached.leadingAnchor.constraint(equalTo: alone.leadingAnchor),
            detached.trailingAnchor.constraint(equalTo: alone.trailingAnchor),
            detached.topAnchor.constraint(equalTo: alone.topAnchor),
        ])
        alone.layoutSubtreeIfNeeded()
        XCTAssertEqual(other.frame.height, 24, "laid out with no window, too")
    }

    func testTheArrowHalvesStepAndStopAtTheEnds() {
        let recorder = Recorder()
        let (stepper, window) = makeField(recorder)
        let b = stepper.bounds
        let up = NSPoint(x: b.maxX - 6, y: b.midY + 4), down = NSPoint(x: b.maxX - 6, y: b.midY - 4)
        XCTAssertNil(stepper.stepDirection(at: NSPoint(x: 8, y: b.midY)), "the number is not an arrow")
        click(stepper, at: up, in: window)
        XCTAssertEqual(stepper.doubleValue, 10_500)
        click(stepper, at: down, in: window)
        click(stepper, at: down, in: window)
        XCTAssertEqual(stepper.doubleValue, 9_500)
        XCTAssertEqual(recorder.values, [10_500, 10_000, 9_500], "each step reports once")
        stepper.doubleValue = 100_000
        click(stepper, at: up, in: window)
        XCTAssertEqual(stepper.doubleValue, 100_000, "the top holds")
        XCTAssertEqual(recorder.values.count, 3, "a step that moves nothing reports nothing, and setting the value reports nothing")
    }

    func testTypedNumbersCommitClampedAndJunkIsPutBack() {
        let recorder = Recorder()
        let (stepper, _) = makeField(recorder)
        stepper.typeForTesting("12,500")
        XCTAssertEqual(stepper.doubleValue, 12_500)
        stepper.typeForTesting("20000")
        XCTAssertEqual(stepper.doubleValue, 20_000, "ungrouped digits read too")
        XCTAssertEqual(stepper.displayedTextForTesting, "20,000")
        stepper.typeForTesting("5000000")
        XCTAssertEqual(stepper.doubleValue, 100_000, "clamped to the top")
        stepper.typeForTesting("lots")
        XCTAssertEqual(stepper.doubleValue, 100_000)
        XCTAssertEqual(stepper.displayedTextForTesting, "100,000", "junk puts the last value back")
        XCTAssertEqual(recorder.values, [12_500, 20_000, 100_000])
    }

    func testUpArrowStepsWhileTyping() {
        let recorder = Recorder()
        let (stepper, _) = makeField(recorder)
        let field = stepper.fieldForTesting
        let editor = NSTextView()
        XCTAssertTrue(stepper.control(field, textView: editor, doCommandBy: #selector(NSResponder.moveUp(_:))))
        XCTAssertEqual(stepper.doubleValue, 10_500)
        XCTAssertEqual(editor.string, "10,500", "the editor shows the new value")
        XCTAssertFalse(stepper.control(field, textView: editor, doCommandBy: #selector(NSResponder.insertTab(_:))), "other keys pass")
    }
}
