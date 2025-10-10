//
//  AppSettingsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
import TangemAccessibilityIdentifiers

final class AppSettingsScreen: ScreenBase<AppSettingsScreenElement> {
    private lazy var currencyButton = button(.currencyButton)

    @discardableResult
    func tapCurrencyButton() -> CurrencySelectionScreen {
        XCTContext.runActivity(named: "Tap currency button") { _ in
            currencyButton.waitAndTap()
            return CurrencySelectionScreen(app)
        }
    }

    @discardableResult
    func validateScreenElements() -> Self {
        XCTContext.runActivity(named: "Validate app settings screen elements") { _ in
            XCTAssertTrue(currencyButton.waitForExistence(timeout: .robustUIUpdate), "Currency button should exist")
            return self
        }
    }

    @discardableResult
    func goBackToDetails() -> DetailsScreen {
        XCTContext.runActivity(named: "Go back to details screen") { _ in
            app.navigationBars.buttons["Details"].waitAndTap()
            return DetailsScreen(app)
        }
    }
}

enum AppSettingsScreenElement: String, UIElement {
    case currencyButton

    var accessibilityIdentifier: String {
        switch self {
        case .currencyButton:
            return AppSettingsAccessibilityIdentifiers.currencyButton
        }
    }
}
