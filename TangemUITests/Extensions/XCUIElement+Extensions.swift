//
//  XCUIElement+Extensions.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation

// MARK: - WaitForState

extension XCUIElement {
    @discardableResult
    func waitAndTap(timeout: TimeInterval = .robustUIUpdate) -> Bool {
        guard waitForExistence(timeout: timeout) else {
            XCTFail("Element '\(self)' did not exist after waiting \(timeout) seconds")
            return false
        }

        guard waitForState(state: .hittable, for: timeout),
              waitForState(state: .enabled, for: timeout) else {
            return false
        }

        guard exists, isHittable, isEnabled else {
            XCTFail("Element '\(self)' is not ready for interaction: exists=\(exists), isHittable=\(isHittable), isEnabled=\(isEnabled)")
            return false
        }

        tap()
        return true
    }

    @discardableResult
    func waitAndTapWithScroll(scrollAttempts: Int = 3, timeout: TimeInterval = .robustUIUpdate) -> Bool {
        if isHittable {
            return waitAndTap(timeout: timeout)
        }

        let app = XCUIApplication()
        let shortTimeout: TimeInterval = 1.0

        for _ in 0 ..< scrollAttempts {
            app.swipeUp()
            if isHittable {
                return waitAndTap(timeout: timeout)
            }
        }

        XCTFail("Element '\(self)' did not exist after \(scrollAttempts) scroll attempts and waiting \(timeout) seconds")
        return false
    }

    @discardableResult
    func waitForState(state: NSPredicateFormat, for timeout: TimeInterval = .robustUIUpdate) -> Bool {
        let predicate = NSPredicate(format: state.rawValue)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)

        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)

        if result != .completed {
            XCTFail("Failed waiting for \(predicate) state of '\(self)' with result: \(result)")
            return false
        }

        return true
    }

    @discardableResult
    func waitForValue(_ expectedValue: String, timeout: TimeInterval = .conditional) -> Bool {
        let predicate = NSPredicate(format: "value == %@", expectedValue)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    @discardableResult
    func waitForValue(timeout: TimeInterval = .conditional, where matches: @escaping (String) -> Bool) -> Bool {
        let predicate = NSPredicate { object, _ in
            guard let value = (object as? XCUIElement)?.value as? String else { return false }
            return matches(value)
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}

// MARK: UI actions

extension XCUIElement {
    func scrollToElement(_ element: XCUIElement, startPoint: Double = 0.8, attempts: SwipeAttempts = .standard) {
        for attempt in 0 ..< attempts.rawValue {
            if !element.isHittable || !element.isEnabled {
                let startCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: startPoint))
                let endCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.1))
                startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
            }
        }
    }

    func scrollHorizontallyToElement(_ element: XCUIElement, startPoint: Double = 0.5, attempts: SwipeAttempts = .standard) {
        for attempt in 0 ..< attempts.rawValue {
            if !element.isHittable || !element.isEnabled {
                let startCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: startPoint))
                let endCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: startPoint))
                startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
            }
        }
    }

    func getValue() -> String {
        guard let value = value as? String, !value.isEmpty else {
            return ""
        }
        return value
    }

    /// Redesigned rows register the gesture on the container, so the inner title is never hittable; fall back to a center-coordinate hit.
    func tapEvenIfNotHittable() {
        // A stale snapshot aborts isHittable/coordinate; wait for a finite frame first.
        waitForStableFrame()
        if isHittable {
            tap()
        } else {
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    /// Waits for a finite, non-empty frame so later hittability reads don't abort on a stale snapshot.
    @discardableResult
    func waitForStableFrame(timeout: TimeInterval = .conditional) -> Bool {
        let predicate = NSPredicate { object, _ in
            guard let element = object as? XCUIElement else { return false }
            let frame = element.frame
            return frame.width > 0 && frame.height > 0
                && frame.minX.isFinite && frame.minY.isFinite
                && frame.width.isFinite && frame.height.isFinite
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    func pressEvenIfNotHittable(forDuration duration: TimeInterval) {
        if isHittable {
            press(forDuration: duration)
        } else {
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: duration)
        }
    }
}

// MARK: Find elements

extension XCUIElement {
    func staticText(identifier: String) -> XCUIElement {
        staticTexts[identifier].firstMatch
    }

    func descendant(element: XCUIElement) -> XCUIElement {
        descendants(matching: element.elementType)[element.identifier].firstMatch
    }

    func staticTextByLabel(label: String) -> XCUIElement {
        staticTexts.element(matching: NSPredicate(format: "label == %@", label))
    }

    func containsLabel(label: String) -> Bool {
        let predicate = NSPredicate(format: NSPredicateFormat.labelContains.rawValue, label)

        let staticTextElements = staticTexts.containing(predicate).allElementsBoundByIndex
        let textViewElements = textViews.containing(predicate).allElementsBoundByIndex
        let links = links.containing(predicate).allElementsBoundByIndex
        return !staticTextElements.isEmpty || !textViewElements.isEmpty || !links.isEmpty
    }

    func containsIdentifier(id: String) -> Bool {
        let predicate = NSPredicate(format: NSPredicateFormat.identifierContains.rawValue, id)
        let otherElements = otherElements.matching(predicate).allElementsBoundByIndex
        let staticTexts = staticTexts.matching(predicate).allElementsBoundByIndex
        let selfContainsIdentifier = identifier.contains(id)
        let buttons = buttons.matching(predicate).allElementsBoundByIndex
        return !otherElements.isEmpty || !buttons.isEmpty || !staticTexts.isEmpty || selfContainsIdentifier
    }
}

// MARK: Check elements

extension XCUIElement {
    func getFirstCells(count: Int = 10) -> [XCUIElement] {
        var firstCells: [XCUIElement] = []
        firstCells.append(contentsOf: cells.allElementsBoundByIndex.prefix(count))
        return firstCells
    }

    func cellsContainingElement(element: XCUIElement) -> XCUIElementQuery {
        cells.containing(element.elementType, identifier: element.identifier)
    }

    func getLabels(identifier: String? = nil, limit: Int = 10) -> [String] {
        var labels: [String] = []
        var elements: [XCUIElement] = []

        if let identifier {
            elements.append(contentsOf: staticTexts.matching(identifier: identifier).allElementsBoundByIndex.prefix(limit))
        } else {
            elements.append(contentsOf: staticTexts.allElementsBoundByIndex.prefix(limit))
        }

        for element in elements {
            labels.append(element.label)
        }

        return labels
    }
}
