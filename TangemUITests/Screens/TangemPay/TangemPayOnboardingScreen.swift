//
//  TangemPayOnboardingScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayOnboardingScreen: Screen {
    let app: XCUIApplication

    private lazy var getCardButton = app.buttons[TangemPayAccessibilityIdentifiers.onboardingGetCardButton].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Tangem Pay onboarding screen") { _ in
            waitAndAssertTrue(getCardButton, timeout: .networkRequest, "Get card button should be displayed on the onboarding screen")
            return self
        }
    }

    @discardableResult
    func tapGetCard() -> Self {
        XCTContext.runActivity(named: "Tap Get card button") { _ in
            getCardButton.waitAndTap()
            return self
        }
    }
}
