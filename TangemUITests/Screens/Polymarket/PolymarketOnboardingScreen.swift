//
//  PolymarketOnboardingScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class PolymarketOnboardingScreen: Screen {
    let app: XCUIApplication

    private lazy var title = app.staticTexts[PolymarketAccessibilityIdentifiers.onboardingTitle].firstMatch
    private lazy var actionButton = app.descendants(matching: .any)
        .matching(identifier: PolymarketAccessibilityIdentifiers.onboardingActionButton)
        .firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForWelcome() -> Self {
        XCTContext.runActivity(named: "Wait for Polymarket welcome screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "Polymarket welcome screen should be displayed")
            XCTAssertEqual(
                title.label,
                Localization.predictionOnboardingTitle,
                "Welcome screen should show the new account title"
            )
            return self
        }
    }

    @discardableResult
    func waitForReconnect() -> Self {
        XCTContext.runActivity(named: "Wait for Polymarket reconnect screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "Polymarket reconnect screen should be displayed")
            XCTAssertEqual(
                title.label,
                Localization.predictionOnboardingReconnectTitle,
                "Reconnect screen should show the existing account title"
            )
            return self
        }
    }

    @discardableResult
    func verifyWelcomeNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify Polymarket onboarding screen is not displayed") { _ in
            XCTAssertTrue(
                title.staysAbsent(for: .absenceCheck),
                "Polymarket onboarding screen should not be displayed"
            )
            return self
        }
    }

    @discardableResult
    func confirmOnboardingExpectingRegionRestrictions() -> PolymarketRegionRestrictionsSheet {
        XCTContext.runActivity(named: "Hold the onboarding action button in a restricted region") { _ in
            waitAndAssertTrue(actionButton, "Onboarding action button should be displayed")
            actionButton.holdToConfirm()
            return PolymarketRegionRestrictionsSheet(app)
        }
    }

    @discardableResult
    func confirmOnboardingExpectingStories() -> PolymarketStoriesScreen {
        XCTContext.runActivity(named: "Hold the onboarding action button of a new account") { _ in
            waitAndAssertTrue(actionButton, "Onboarding action button should be displayed")
            actionButton.holdToConfirm()
            return PolymarketStoriesScreen(app)
        }
    }

    @discardableResult
    func confirmOnboarding() -> PolymarketMainScreen {
        XCTContext.runActivity(named: "Hold the onboarding action button") { _ in
            waitAndAssertTrue(actionButton, "Onboarding action button should be displayed")
            actionButton.holdToConfirm()
            return PolymarketMainScreen(app)
        }
    }
}
