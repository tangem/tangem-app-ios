//
//  CurrencySelectionScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
import TangemAccessibilityIdentifiers

final class CurrencySelectionScreen: ScreenBase<CurrencySelectionScreenElement> {
    private lazy var searchField = searchField(.searchField)
    private lazy var backButton = button(.backButton)

    @discardableResult
    func searchCurrency(_ currency: String) -> Self {
        XCTContext.runActivity(named: "Search for currency: \(currency)") { _ in
            searchField.waitAndTap()
            searchField.typeText(currency)
            return self
        }
    }

    @discardableResult
    func selectCurrency(_ currency: String) -> AppSettingsScreen {
        XCTContext.runActivity(named: "Select currency: \(currency)") { _ in
            searchCurrency(currency)

            let currencyButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[cd] %@", currency)).firstMatch
            XCTAssertTrue(currencyButton.waitForExistence(timeout: .robustUIUpdate), "Currency button containing '\(currency)' should exist")
            currencyButton.waitAndTap()
            return AppSettingsScreen(app)
        }
    }

    @discardableResult
    func validateScreenElements() -> Self {
        XCTContext.runActivity(named: "Validate currency selection screen elements") { _ in
            XCTAssertTrue(searchField.waitForExistence(timeout: .robustUIUpdate), "Search field should exist")
            return self
        }
    }
}

enum CurrencySelectionScreenElement: String, UIElement {
    case searchField
    case backButton

    var accessibilityIdentifier: String {
        switch self {
        case .searchField:
            return "Search"
        case .backButton:
            return "Back"
        }
    }
}
