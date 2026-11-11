//
//  PolymarketStoriesScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class PolymarketStoriesScreen: Screen {
    let app: XCUIApplication

    private lazy var firstStoryTitle = app.staticTexts
        .matching(identifier: StoriesAccessibilityIdentifiers.storyContainer(page: .zero))
        .matching(NSPredicate(format: "label == %@", Localization.predictionOnboardingStoryFirstTitle))
        .firstMatch
    private lazy var firstStorySubtitle = app.staticTexts
        .matching(identifier: StoriesAccessibilityIdentifiers.storyContainer(page: .zero))
        .matching(NSPredicate(format: "label == %@", Localization.predictionOnboardingStoryFirstSubtitle))
        .firstMatch
    private lazy var closeButton = app.buttons[StoriesAccessibilityIdentifiers.closeButton].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForStories() -> Self {
        XCTContext.runActivity(named: "Wait for the Polymarket onboarding stories") { _ in
            waitAndAssertTrue(firstStoryTitle, timeout: .networkRequest, "The first story title should be displayed")
            waitAndAssertTrue(firstStorySubtitle, "The first story subtitle should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the Polymarket onboarding stories are not displayed") { _ in
            XCTAssertTrue(firstStoryTitle.staysAbsent(for: .absenceCheck), "Onboarding stories should not be displayed")
            return self
        }
    }

    @discardableResult
    func close() -> PolymarketMainScreen {
        XCTContext.runActivity(named: "Close the Polymarket onboarding stories") { _ in
            XCTAssertTrue(closeButton.waitAndTap(), "Stories close button should be tappable")
            return PolymarketMainScreen(app)
        }
    }
}
