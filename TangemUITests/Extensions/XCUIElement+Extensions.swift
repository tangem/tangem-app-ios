//
//  XCUIElement+Extensions.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

// MARK: - WaitForState

extension XCUIElement {
    @discardableResult
    func waitForState(state: NSPredicateFormat, for timeout: TimeInterval = .quickUIUpdate) -> Bool {
        let testCase = XCTestCase()
        let predicate = NSPredicate(format: state.rawValue)
        _ = testCase.expectation(for: predicate, evaluatedWith: self)
        testCase.waitForExpectations(timeout: timeout) { error in
            if error != nil {
                XCTFail("Timed out after waiting for \(timeout) seconds for \(predicate) state of '\(self)'")
            }
        }
        return true
    }
}

// MARK: UI actions

extension XCUIElement {
    func scrollToElement(_ element: XCUIElement, startPoint: Double = 0.8, attempts: SwipeAttempts = .standard) {
        for attempt in 0 ..< attempts.rawValue {
            if !element.isHittable || !element.isEnabled {
                log.debug("Swiping - attempt \(attempt)")
                let startCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: startPoint))
                let endCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.1))
                startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
            }
        }
    }

    func scrollHorizontallyToElement(_ element: XCUIElement, startPoint: Double = 0.5, attempts: SwipeAttempts = .standard) {
        for attempt in 0 ..< attempts.rawValue {
            if !element.isHittable || !element.isEnabled {
                log.debug("Swiping - attempt \(attempt)")
                let startCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: startPoint))
                let endCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: startPoint))
                startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
            }
        }
    }

    func editText(text: String) {
        app.scrollToElement(self)
        let clearButton = app.buttons["Clear text"].firstMatch
        if !hasFocus {
            tap()
        }
        if clearButton.exists {
            clearButton.tap()
        }
        typeText(text)
        app.hideKeyboardIfNeeded()
    }

    func clearText() {
        app.scrollToElement(self)
        if !hasFocus {
            tap()
        }

        guard let value = value as? String, value.isNotEmpty else {
            return
        }

        for char in String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count) {
            typeText(String(char))
        }
    }

    func deleteText() {
        if !hasFocus {
            doubleTap()
        } else {
            tap()
        }
        let selectAllMenuItem = app.menuItems["Select All"]
        if selectAllMenuItem.waitForExistence(timeout: 1) {
            selectAllMenuItem.tap()
        }
        typeText("\u{8}")
    }

    func getValue() -> String {
        guard let value = value as? String, value.isNotEmpty else {
            return ""
        }
        return value
    }

    func hideKeyboardIfNeeded() {
        let keyboardDoneButton = toolbars.buttons["KeyboardDoneButton"].firstMatch
        let doneButton = toolbars.buttons["Done"].firstMatch
        if keyboardDoneButton.exists {
            keyboardDoneButton.tap()
        } else if doneButton.exists {
            doneButton.tap()
        }
    }

    func pressAndDragDown() {
        let startCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let endCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1.0))
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
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
        return staticTextElements.isNotEmpty textViewElements.isNotEmpty links.isNotEmpty
    }

    func containsIdentifier(id: String) -> Bool {
        let predicate = NSPredicate(format: NSPredicateFormat.identifierContains.rawValue, id)
        let otherElements = otherElements.matching(predicate).allElementsBoundByIndex
        let staticTexts = staticTexts.matching(predicate).allElementsBoundByIndex
        let selfContainsIdentifier = identifier.contains(id)
        let buttons = buttons.matching(predicate).allElementsBoundByIndex
        return otherElements.isNotEmpty buttons.isNotEmpty staticTexts.isNotEmpty || selfContainsIdentifier
    }

    func isVisible() -> Bool {
        app.scrollToElement(self, attempts: .serp)
        return isHittable
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
