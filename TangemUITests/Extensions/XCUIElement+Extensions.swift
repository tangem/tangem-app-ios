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
    func waitAndTap(timeout: TimeInterval = .longUIUpdate, waitForHittable: Bool = true) -> Bool {
        guard waitForExistence(timeout: timeout) else {
            XCTFail("Element '\(self)' did not exist after waiting \(timeout) seconds")
            return false
        }

        if waitForHittable {
            guard waitForState(state: .hittable, for: timeout) else {
                XCTFail("Element '\(self)' was not hittable after waiting \(timeout) seconds")
                return false
            }
        }

        // Дополнительная проверка перед tap для CI стабильности
        guard isHittable else {
            XCTFail("Element '\(self)' became unhittable just before tap")
            return false
        }

        tap()
        return true
    }

    @discardableResult
    func waitForState(state: NSPredicateFormat, for timeout: TimeInterval = .quickUIUpdate) -> Bool {
        let predicate = NSPredicate(format: state.rawValue)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)

        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)

        if result != .completed {
            XCTFail("Failed waiting for \(predicate) state of '\(self)' with result: \(result)")
            return false
        }

        return true
    }
}

// MARK: UI actions

extension XCUIElement {
    func scrollToElement(_ element: XCUIElement, startPoint: Double = 0.8, attempts: SwipeAttempts = .standard) {
        for attempt in 0 ..< attempts.rawValue {
            if !element.isHittable || !element.isEnabled {
//                log.debug("Swiping - attempt \(attempt)")
                let startCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: startPoint))
                let endCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.1))
                startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
            }
        }
    }

    func scrollHorizontallyToElement(_ element: XCUIElement, startPoint: Double = 0.5, attempts: SwipeAttempts = .standard) {
        for attempt in 0 ..< attempts.rawValue {
            if !element.isHittable || !element.isEnabled {
//                log.debug("Swiping - attempt \(attempt)")
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
        staticTexts.element(matching: NSPredicate(format: NSPredicateFormat.labelContains.rawValue, label))
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
