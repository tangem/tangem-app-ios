//
//  UIElementPage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

class UIElementPage<T: UIElement>: Page {
    let app: XCUIApplication

    init(app: XCUIApplication, rootUIElement: UIElement) {
        self.app = app

        super.init(element: app.otherElements[rootUIElement.accessibilityIdentifier])
    }

    init(app: XCUIApplication, rootXCUIElement: XCUIElement) {
        self.app = app

        let element: XCUIElement = switch rootXCUIElement.elementType {
        case .cell:
            app.cells[rootXCUIElement.identifier]
        default:
            app.otherElements[rootXCUIElement.identifier]
        }

        super.init(element: element)
    }
}
