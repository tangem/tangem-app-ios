//
//  TangemPayWithdrawHubScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayWithdrawHubScreen: ScreenBase<TangemPayWithdrawHubScreenElement> {
    private lazy var withinPortfolioTile = button(.withinPortfolioTile)
    private lazy var personalAccountTile = button(.personalAccountTile)
    private lazy var businessAccountTile = button(.businessAccountTile)
    private lazy var recentAccountsRetryTile = button(.recentAccountsRetryTile)
    private lazy var seeAllTile = button(.seeAllTile)
    private lazy var recentAccountTiles = app.buttons.matching(identifier: TangemPayOfframpAccessibilityIdentifiers.hubRecentAccountTile)
    private lazy var bankTransferUnavailableSubtitle = app.staticTexts[Localization.tangempayWithdrawHubBankSectionSubtitleUnavailable].firstMatch

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for the Withdraw hub") { _ in
            waitAndAssertTrue(personalAccountTile, timeout: .networkRequest, "To personal account tile should be displayed")
            waitAndAssertTrue(withinPortfolioTile, "Within your portfolio tile should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the Withdraw hub is not displayed") { _ in
            XCTAssertFalse(personalAccountTile.exists, "Withdraw hub should not be displayed")
            return self
        }
    }

    @discardableResult
    func verifyRecentsZeroStateInBothSections() -> Self {
        XCTContext.runActivity(named: "Verify the zero state in Transfer or swap and Bank transfer") { _ in
            waitAndAssertTrue(
                placeholder(.recentTokensEmpty),
                timeout: .networkRequest,
                "Transfer or swap should show '\(Localization.tangempayWithdrawHubRecentsEmpty)'"
            )
            verifyBankRecentsZeroState()
            return self
        }
    }

    @discardableResult
    func verifyBankRecentsZeroState() -> Self {
        XCTContext.runActivity(named: "Verify the Bank transfer zero state") { _ in
            waitAndAssertTrue(
                placeholder(.recentAccountsEmpty),
                timeout: .networkRequest,
                "Bank transfer should show '\(Localization.tangempayWithdrawHubRecentsEmpty)'"
            )
            return self
        }
    }

    @discardableResult
    func verifyRecentAccountsLoadError() -> Self {
        XCTContext.runActivity(named: "Verify the recent bank transfers error tile") { _ in
            waitAndAssertTrue(recentAccountsRetryTile, timeout: .networkRequest, "Recent bank transfers error tile should be displayed")
            XCTAssertTrue(
                recentAccountsRetryTile.label.contains(Localization.tangempayWithdrawHubAccountsLoadError),
                "Error tile should read '\(Localization.tangempayWithdrawHubAccountsLoadError)'. Actual: '\(recentAccountsRetryTile.label)'"
            )
            return self
        }
    }

    @discardableResult
    func tapRecentAccountsRetry() -> Self {
        XCTContext.runActivity(named: "Tap the recent bank transfers error tile") { _ in
            recentAccountsRetryTile.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyBankTransferUnavailable() -> Self {
        XCTContext.runActivity(named: "Verify the Bank transfer block is unavailable") { _ in
            waitAndAssertTrue(
                bankTransferUnavailableSubtitle,
                timeout: .networkRequest,
                "Bank transfer should read '\(Localization.tangempayWithdrawHubBankSectionSubtitleUnavailable)'"
            )
            XCTAssertTrue(personalAccountTile.waitForState(state: .disabled), "To personal account should be disabled")
            XCTAssertTrue(businessAccountTile.waitForState(state: .disabled), "To business account should be disabled")
            return self
        }
    }

    @discardableResult
    func verifyRecentRecipient(_ recipient: TangemPayBankRecipient) -> Self {
        XCTContext.runActivity(named: "Verify recent recipient '\(recipient.shortName)'") { _ in
            let tile = recentAccountTile(containing: recipient.shortName)
            waitAndAssertTrue(tile, timeout: .networkRequest, "Recent recipient '\(recipient.shortName)' should be displayed")
            XCTAssertTrue(
                tile.label.contains(recipient.accountNumber),
                "'\(recipient.shortName)' tile should show '\(recipient.accountNumber)'. Actual: '\(tile.label)'"
            )
            XCTAssertTrue(
                recipient.isMonogramLeading(in: tile.label),
                "'\(recipient.shortName)' tile should start with the monogram '\(recipient.monogram)'. Actual: '\(tile.label)'"
            )
            return self
        }
    }

    @discardableResult
    func tapRecentRecipient(_ recipient: TangemPayBankRecipient) -> TangemPayBankTransferAmountScreen {
        XCTContext.runActivity(named: "Tap recent recipient '\(recipient.shortName)'") { _ in
            recentAccountTile(containing: recipient.shortName).waitAndTap(timeout: .networkRequest)
            return TangemPayBankTransferAmountScreen(app).waitForScreen()
        }
    }

    @discardableResult
    func verifyRecentRecipientNotDisplayed(_ recipient: TangemPayBankRecipient) -> Self {
        XCTContext.runActivity(named: "Verify '\(recipient.shortName)' is not among recent recipients") { _ in
            XCTAssertFalse(
                recentAccountTile(containing: recipient.shortName).exists,
                "'\(recipient.shortName)' should not be among recent recipients"
            )
            return self
        }
    }

    @discardableResult
    func verifyRecentRecipientCount(_ count: Int) -> Self {
        XCTContext.runActivity(named: "Verify \(count) recent recipients are displayed") { _ in
            let countMatches = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == %d", count), object: recentAccountTiles)
            XCTAssertEqual(
                XCTWaiter().wait(for: [countMatches], timeout: .networkRequest),
                .completed,
                "Bank transfer should show exactly \(count) recent recipients, but shows \(recentAccountTiles.count)"
            )
            return self
        }
    }

    @discardableResult
    func verifySeeAllDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify See all is displayed") { _ in
            waitAndAssertTrue(seeAllTile, "See all should be displayed")
            XCTAssertTrue(seeAllTile.label.contains(Localization.commonSeeAll), "See all tile should read '\(Localization.commonSeeAll)'")
            return self
        }
    }

    @discardableResult
    func verifySeeAllNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify See all is not displayed") { _ in
            XCTAssertFalse(seeAllTile.exists, "See all should not be displayed")
            return self
        }
    }

    @discardableResult
    func verifyRecentToken(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Verify recent token '\(tokenName)' in Transfer or swap") { _ in
            let predicate = NSPredicate(
                format: "identifier == %@ AND label CONTAINS %@",
                TangemPayOfframpAccessibilityIdentifiers.hubRecentTokenTile,
                tokenName
            )
            waitAndAssertTrue(
                app.buttons.matching(predicate).firstMatch,
                timeout: .networkRequest,
                "Recent token '\(tokenName)' should be displayed in Transfer or swap"
            )
            return self
        }
    }

    @discardableResult
    func tapSeeAll() -> TangemPayBankRecipientsScreen {
        XCTContext.runActivity(named: "Tap See all") { _ in
            waitAndAssertTrue(seeAllTile, timeout: .networkRequest, "See all should be displayed")
            scrollRecentAccountsCarousel(to: seeAllTile)
            seeAllTile.waitAndTap()
            return TangemPayBankRecipientsScreen(app).waitForScreen()
        }
    }

    @discardableResult
    func tapToPersonalAccount() -> TangemPayBankTransferAmountScreen {
        XCTContext.runActivity(named: "Tap To personal account") { _ in
            personalAccountTile.waitAndTap(timeout: .networkRequest)
            return TangemPayBankTransferAmountScreen(app).waitForScreen()
        }
    }

    @discardableResult
    func tapToBusinessAccount() -> TangemPayBankTransferAmountScreen {
        XCTContext.runActivity(named: "Tap To business account") { _ in
            businessAccountTile.waitAndTap(timeout: .networkRequest)
            return TangemPayBankTransferAmountScreen(app).waitForScreen()
        }
    }

    @discardableResult
    func tapWithinPortfolio() -> SwapScreen {
        XCTContext.runActivity(named: "Tap Within your portfolio") { _ in
            withinPortfolioTile.waitAndTap()
            return SwapScreen(app).validateSwapScreenDisplayed()
        }
    }

    @discardableResult
    func close() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Close the Withdraw hub") { _ in
            guard let closeButton = app.buttons.matching(NSPredicate(format: "label == %@", Localization.commonClose)).firstHittableElement() else {
                XCTFail("Withdraw hub Close button should become hittable")
                return TangemPayMainScreen(app)
            }
            closeButton.tap()
            XCTAssertTrue(personalAccountTile.waitForNonExistence(timeout: .conditional), "Withdraw hub should be dismissed")
            return TangemPayMainScreen(app).waitForScreen()
        }
    }

    private func placeholder(_ element: TangemPayWithdrawHubScreenElement) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier == %@ AND label CONTAINS %@",
            element.accessibilityIdentifier,
            Localization.tangempayWithdrawHubRecentsEmpty
        )
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    private func scrollRecentAccountsCarousel(to element: XCUIElement) {
        let screenFrame = app.windows.firstMatch.frame
        for _ in 0 ..< Constants.carouselSwipeAttempts where !screenFrame.contains(element.frame) {
            guard let visibleTile = recentAccountTiles.allElementsBoundByIndex.last(where: { screenFrame.contains($0.frame) }) else {
                break
            }
            visibleTile.swipeLeft()
        }
        XCTAssertTrue(screenFrame.contains(element.frame), "'\(element)' should be scrolled into view")
    }

    private func recentAccountTile(containing name: String) -> XCUIElement {
        recentAccountTiles.matching(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
    }
}

enum TangemPayWithdrawHubScreenElement: String, UIElement {
    case withinPortfolioTile
    case personalAccountTile
    case businessAccountTile
    case recentTokensEmpty
    case recentAccountsEmpty
    case recentAccountsRetryTile
    case seeAllTile

    var accessibilityIdentifier: String {
        switch self {
        case .withinPortfolioTile:
            TangemPayOfframpAccessibilityIdentifiers.hubWithinPortfolioTile
        case .personalAccountTile:
            TangemPayOfframpAccessibilityIdentifiers.hubPersonalAccountTile
        case .businessAccountTile:
            TangemPayOfframpAccessibilityIdentifiers.hubBusinessAccountTile
        case .recentTokensEmpty:
            TangemPayOfframpAccessibilityIdentifiers.hubRecentTokensEmpty
        case .recentAccountsEmpty:
            TangemPayOfframpAccessibilityIdentifiers.hubRecentAccountsEmpty
        case .recentAccountsRetryTile:
            TangemPayOfframpAccessibilityIdentifiers.hubRecentAccountsRetry
        case .seeAllTile:
            TangemPayOfframpAccessibilityIdentifiers.hubSeeAllTile
        }
    }
}

private extension TangemPayWithdrawHubScreen {
    enum Constants {
        static let carouselSwipeAttempts = 4
    }
}
