//
//  PolymarketMainScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class PolymarketMainScreen: Screen {
    let app: XCUIApplication

    private lazy var title = app.staticTexts[PolymarketAccessibilityIdentifiers.mainScreenTitle].firstMatch
    private lazy var availableBalanceLabel = app.staticTexts[Localization.predictionMainAvailableBalance].firstMatch
    private lazy var availableBalance = app.staticTexts
        .matching(NSPredicate(format: "label BEGINSWITH %@", Constants.availableBalancePrefix))
        .firstMatch
    private lazy var addFundsButton = app.buttons[PolymarketAccessibilityIdentifiers.addFundsButton].firstMatch
    private lazy var withdrawButton = app.buttons[PolymarketAccessibilityIdentifiers.withdrawButton].firstMatch
    private lazy var overflowMenuButton = app.buttons[PolymarketAccessibilityIdentifiers.overflowMenuButton].firstMatch
    private lazy var historyMenuItem = app.buttons[Localization.predictionHistoryTitle].firstMatch
    private lazy var activePositionsTitle = app.staticTexts[Localization.predictionPositionsMainTitle].firstMatch
    private lazy var firstPosition = positionButton(titled: Constants.activePositionTitle)
    private lazy var redeemablePosition = positionButton(titled: Constants.redeemablePositionTitle)
    private lazy var firstOutcomeButton = app.buttons
        .matching(NSPredicate(format: "label MATCHES %@", Constants.outcomeButtonPattern))
        .firstMatch
    private lazy var regionBanner = app.descendants(matching: .any)
        .matching(identifier: PolymarketAccessibilityIdentifiers.regionRestrictionBanner)
        .firstMatch
    private lazy var regionBannerTitle = regionBannerText(Localization.predictionRegionRestrictionsTitle)
    private lazy var regionBannerSubtitle = regionBannerText(Localization.predictionRegionRestrictionsSubtitle)
    private lazy var storiesCloseButton = app.buttons[StoriesAccessibilityIdentifiers.closeButton].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Polymarket main screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "Polymarket main screen should be displayed")
            return self
        }
    }

    @discardableResult
    func closeOnboardingStoriesIfDisplayed() -> Self {
        XCTContext.runActivity(named: "Close the onboarding stories when they are displayed") { _ in
            if storiesCloseButton.waitForExistence(timeout: .conditional) {
                XCTAssertTrue(storiesCloseButton.waitAndTap(), "Stories close button should be tappable")
            }
            return self
        }
    }

    @discardableResult
    func goBack() -> MainScreen {
        tapBackButton(to: MainScreen.self)
    }

    @discardableResult
    func verifyRegionBannerDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the region restrictions banner is displayed") { _ in
            waitAndAssertTrue(regionBanner, timeout: .networkRequest, "Region restrictions banner should be displayed")
            waitAndAssertTrue(regionBannerTitle, "Region restrictions banner should show its title")
            waitAndAssertTrue(regionBannerSubtitle, "Region restrictions banner should show its subtitle")
            return self
        }
    }

    @discardableResult
    func verifyRegionBannerNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the region restrictions banner is not displayed") { _ in
            XCTAssertTrue(
                regionBanner.staysAbsent(for: .absenceCheck),
                "Region restrictions banner should not be displayed"
            )
            return self
        }
    }

    @discardableResult
    func verifyAvailableBalanceDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the available balance is displayed") { _ in
            waitAndAssertTrue(availableBalanceLabel, timeout: .networkRequest, "Available balance label should be displayed")
            waitAndAssertTrue(availableBalance, timeout: .networkRequest, "Available balance should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyWithdrawEnabled() -> Self {
        XCTContext.runActivity(named: "Verify the Withdraw button is enabled") { _ in
            waitAndAssertTrue(withdrawButton, "Withdraw button should be displayed")
            XCTAssertTrue(withdrawButton.isEnabled, "Withdraw button should be enabled")
            return self
        }
    }

    @discardableResult
    func verifyActivePositionsDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the active positions are displayed") { _ in
            waitAndAssertTrue(activePositionsTitle, timeout: .networkRequest, "Positions title should be displayed")
            waitAndAssertTrue(firstPosition, timeout: .networkRequest, "Active position should be displayed")
            return self
        }
    }

    @discardableResult
    func openHistory() -> PolymarketHistoryScreen {
        XCTContext.runActivity(named: "Open the history from the overflow menu") { _ in
            XCTAssertTrue(overflowMenuButton.waitAndTap(), "Overflow menu button should be tappable")
            XCTAssertTrue(historyMenuItem.waitAndTap(), "History menu item should be tappable")
            return PolymarketHistoryScreen(app)
        }
    }

    @discardableResult
    func openAddFunds() -> PolymarketAddFundsSheet {
        XCTContext.runActivity(named: "Tap the Add funds button") { _ in
            XCTAssertTrue(addFundsButton.waitAndTap(timeout: .networkRequest), "Add funds button should be tappable")
            return PolymarketAddFundsSheet(app)
        }
    }

    @discardableResult
    func openRegionRestrictionsFromAddFunds() -> PolymarketRegionRestrictionsSheet {
        XCTContext.runActivity(named: "Tap the Add funds button in a restricted region") { _ in
            XCTAssertTrue(addFundsButton.waitAndTap(timeout: .networkRequest), "Add funds button should be tappable")
            return PolymarketRegionRestrictionsSheet(app)
        }
    }

    @discardableResult
    func tapWithdraw() -> PolymarketWithdrawScreen {
        XCTContext.runActivity(named: "Tap the Withdraw button") { _ in
            XCTAssertTrue(withdrawButton.waitAndTap(timeout: .networkRequest), "Withdraw button should be tappable")
            return PolymarketWithdrawScreen(app)
        }
    }

    @discardableResult
    func openFirstPosition() -> PolymarketPositionDetailsScreen {
        XCTContext.runActivity(named: "Open the first position") { _ in
            XCTAssertTrue(firstPosition.waitAndTap(timeout: .networkRequest), "First position should be tappable")
            return PolymarketPositionDetailsScreen(app)
        }
    }

    @discardableResult
    func openRedeemablePosition() -> PolymarketRedeemSheet {
        XCTContext.runActivity(named: "Open the redeemable position") { _ in
            XCTAssertTrue(redeemablePosition.waitAndTap(timeout: .networkRequest), "Redeemable position should be tappable")
            return PolymarketRedeemSheet(app)
        }
    }

    @discardableResult
    func openFirstOutcome() -> PolymarketOrderSheet {
        XCTContext.runActivity(named: "Tap the first outcome button") { _ in
            XCTAssertTrue(firstOutcomeButton.waitAndTap(timeout: .networkRequest), "First outcome button should be tappable")
            return PolymarketOrderSheet(app, intent: .buy)
        }
    }

    @discardableResult
    func verifyFirstOutcomeDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the first outcome button is displayed") { _ in
            for _ in 0 ..< Constants.feedSwipeAttempts where !firstOutcomeButton.exists {
                app.swipeUp()
            }

            waitAndAssertTrue(firstOutcomeButton, timeout: .networkRequest, "First outcome button should be displayed")
            return self
        }
    }

    private func regionBannerText(_ text: String) -> XCUIElement {
        regionBanner.staticTexts[text].firstMatch
    }

    private func positionButton(titled title: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
    }
}

private extension PolymarketMainScreen {
    enum Constants {
        static let availableBalancePrefix = "$25"
        static let activePositionTitle = "Will the mock prediction come true?"
        static let redeemablePositionTitle = "Will the redeemable mock prediction resolve?"
        static let outcomeButtonPattern = "(Yes|No) [0-9]+¢"
        static let feedSwipeAttempts = 5
    }
}
