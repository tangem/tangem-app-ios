//
//  UIElementPage+Extension.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

extension UIElementPage {
    func button(_ element: T) -> XCUIElement {
        app.buttons[element.accessibilityIdentifier].firstMatch
    }

    func button(_ label: String) -> XCUIElement {
        app.buttons[label].firstMatch
    }

    func staticText(_ element: T) -> XCUIElement {
        app.staticTexts[element.accessibilityIdentifier].firstMatch
    }

    func staticTexts(_ element: T) -> XCUIElementQuery {
        app.staticTexts.matching(identifier: element.accessibilityIdentifier)
    }

    func staticText(identifierContains particle: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: NSPredicateFormat.identifierContains.rawValue, particle)).firstMatch
    }

    func cell(_ element: T) -> XCUIElement {
        app.cells[element.accessibilityIdentifier].firstMatch
    }

    func slider(_ element: T) -> XCUIElement {
        app.sliders[element.accessibilityIdentifier].firstMatch
    }

    func textField(_ element: T) -> XCUIElement {
        app.textFields[element.accessibilityIdentifier].firstMatch
    }

    func secureTextField(_ element: T) -> XCUIElement {
        app.secureTextFields[element.accessibilityIdentifier].firstMatch
    }

    func textView(_ element: T) -> XCUIElement {
        app.textViews[element.accessibilityIdentifier].firstMatch
    }

    func otherElement(_ element: T) -> XCUIElement {
        app.otherElements[element.accessibilityIdentifier].firstMatch
    }

    func otherElements(_ element: T) -> XCUIElementQuery {
        app.otherElements.matching(identifier: element.accessibilityIdentifier)
    }

    func collectionView(_ element: T) -> XCUIElement {
        app.collectionViews[element.accessibilityIdentifier].firstMatch
    }

    func collectionViews(_ element: T) -> XCUIElementQuery {
        app.collectionViews.matching(identifier: element.accessibilityIdentifier)
    }

    func cellsInCollectionView(_ element: T) -> XCUIElementQuery {
        app.collectionViews[element.accessibilityIdentifier].firstMatch.cells
    }

    func staticTextByLabel(label: String) -> XCUIElement {
        app.staticTexts.element(matching: NSPredicate(format: NSPredicateFormat.labelContains.rawValue, label))
    }

    func cellContainsLabel(label: String) -> XCUIElementQuery {
        app.cells.containing(NSPredicate(format: NSPredicateFormat.labelContains.rawValue, label))
    }

    func table(_ element: T) -> XCUIElement {
        app.tables[element.accessibilityIdentifier].firstMatch
    }

    func cellsInTable(_ element: T) -> XCUIElementQuery {
        app.tables[element.accessibilityIdentifier].firstMatch.cells
    }

    func pickerWheel() -> XCUIElement {
        app.pickerWheels.firstMatch
    }

    func image(_ element: T) -> XCUIElement {
        app.images[element.accessibilityIdentifier].firstMatch
    }

    func images(_ element: T) -> XCUIElementQuery {
        app.images.matching(identifier: element.accessibilityIdentifier)
    }

    func pullToRefresh() {
        let startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let finishCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))

        startCoordinate.press(forDuration: 0.05, thenDragTo: finishCoordinate)
    }

    func gentleSwipeUp() {
//        log.debug("Gently swiping up...")
        let startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let endCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        startCoordinate.press(
            forDuration: 0.1,
            thenDragTo: endCoordinate,
            withVelocity: .slow,
            thenHoldForDuration: .zero
        )
    }
}
