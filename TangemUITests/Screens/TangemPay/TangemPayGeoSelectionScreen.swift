//
//  TangemPayGeoSelectionScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayGeoSelectionScreen: Screen {
    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForScreen(title: String) -> Self {
        XCTContext.runActivity(named: "Wait for '\(title)' selection screen") { _ in
            waitAndAssertTrue(app.staticTexts[title].firstMatch, timeout: .networkRequest, "'\(title)' screen should be displayed")
            return self
        }
    }

    @discardableResult
    func selectRow(_ title: String) -> Self {
        XCTContext.runActivity(named: "Select '\(title)'") { _ in
            row(title).waitAndTap(timeout: .networkRequest)
            return self
        }
    }

    @discardableResult
    func waitForClosed(title: String) -> Self {
        XCTContext.runActivity(named: "Wait for '\(title)' selection screen to close") { _ in
            XCTAssertTrue(
                app.staticTexts[title].firstMatch.waitForNonExistence(timeout: .networkRequest),
                "'\(title)' screen should close after the selection"
            )
            return self
        }
    }

    private func row(_ title: String) -> XCUIElement {
        app.buttons
            .matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", TangemPayAccessibilityIdentifiers.geoSelectionRow, title))
            .firstMatch
    }
}
