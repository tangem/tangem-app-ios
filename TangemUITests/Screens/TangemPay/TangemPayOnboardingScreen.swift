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
    func verifyNotDisplayed(for duration: TimeInterval = .conditional) -> Self {
        XCTContext.runActivity(named: "Verify Tangem Pay onboarding screen does not open") { _ in
            XCTAssertTrue(getCardButton.staysAbsent(for: duration), "Tangem Pay onboarding screen should not open")
            return self
        }
    }

    @discardableResult
    func tapGetCard() -> MainScreen {
        XCTContext.runActivity(named: "Tap Get card button") { _ in
            getCardButton.waitAndTap()
            return MainScreen(app)
        }
    }

    @discardableResult
    func tapGetCardExpectingUnlock() -> MobileUnlockScreen {
        XCTContext.runActivity(named: "Tap Get card button and expect wallet unlock") { _ in
            getCardButton.waitAndTap()
            return MobileUnlockScreen(app)
        }
    }
}
