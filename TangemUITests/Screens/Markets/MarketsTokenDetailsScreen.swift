//
//  MarketsTokenDetailsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import XCTest

final class MarketsTokenDetailsScreen: ScreenBase<MarketsTokenDetailsScreenElement> {
    private lazy var listedOnExchangesButton = button(.listedOnExchangesButton)
    private lazy var securityScoreBlock = otherElement(.securityScoreBlock)
    private lazy var securityScoreValue = staticText(.securityScoreValue)
    private lazy var securityScoreRatingStars = image(.securityScoreRatingStars)
    private lazy var securityScoreReviewsCount = staticText(.securityScoreReviewsCount)

    @discardableResult
    func verifyListedOnExchangesBlock() -> Self {
        XCTContext.runActivity(named: "Verify 'Listed on exchanges' block is displayed") { _ in
            waitAndAssertTrue(
                listedOnExchangesButton,
                "Listed on exchanges button should exist and be visible"
            )
            return self
        }
    }

    @discardableResult
    func openExchanges() -> MarketsExchangeScreen {
        XCTContext.runActivity(named: "Open exchanges list") { _ in
            if !listedOnExchangesButton.isHittable {
                app.swipeUp()
            }

            listedOnExchangesButton.waitAndTap()
            return MarketsExchangeScreen(app)
        }
    }

    @discardableResult
    func verifyListedOnExchangesBlockEmpty() -> Self {
        XCTContext.runActivity(named: "Verify 'Listed on exchanges' block is empty and disabled") {
            _ in
            let listedOnLabel = app.staticTexts[
                MarketsAccessibilityIdentifiers.listedOnExchangesTitle
            ]

            if !listedOnLabel.waitForExistence(timeout: .robustUIUpdate) {
                app.swipeUp()
            }

            waitAndAssertTrue(listedOnLabel, "'Listed on' label should exist")

            let noExchangesLabel = app.staticTexts[
                MarketsAccessibilityIdentifiers.listedOnExchangesEmptyText
            ]

            waitAndAssertTrue(noExchangesLabel, "'No exchanges found' label should exist")

            return self
        }
    }

    // MARK: - Security Score

    @discardableResult
    func verifySecurityScoreBlockDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify 'Security Score' block is displayed") { _ in
            waitAndAssertTrue(
                securityScoreBlock,
                "Security Score block should be visible"
            )
            return self
        }
    }

    @discardableResult
    func verifySecurityScoreBlockHidden() -> Self {
        XCTContext.runActivity(named: "Verify 'Security Score' block is hidden") { _ in
            let blockExists = securityScoreBlock.waitForExistence(timeout: .quick)
            XCTAssertFalse(
                blockExists,
                "Security Score block should not be visible for tokens without security data"
            )
            return self
        }
    }

    @discardableResult
    func openSecurityScoreDetails() -> MarketsSecurityScoreDetailsScreen {
        XCTContext.runActivity(named: "Open Security Score details") { _ in
            let infoButton = app.buttons[MarketsAccessibilityIdentifiers.securityScoreInfoButton]
            waitAndAssertTrue(infoButton, "Security Score info button should be visible")
            infoButton.tap()
            return MarketsSecurityScoreDetailsScreen(app)
        }
    }

    @discardableResult
    func verifySecurityScoreValue() -> Self {
        XCTContext.runActivity(named: "Verify Security Score value is displayed") { _ in
            waitAndAssertTrue(
                securityScoreValue,
                "Security Score value should be visible"
            )

            let scoreText = securityScoreValue.label
            XCTAssertFalse(scoreText.isEmpty, "Security Score value should not be empty")

            // Verify score format (e.g., "4.6")
            let scorePattern = "^\\d+\\.\\d+$"
            let scoreRegex = try? NSRegularExpression(pattern: scorePattern)
            let range = NSRange(scoreText.startIndex..., in: scoreText)
            let hasValidFormat = scoreRegex?.firstMatch(in: scoreText, range: range) != nil

            XCTAssertTrue(
                hasValidFormat,
                "Security Score '\(scoreText)' should have valid format (e.g., '4.6')"
            )

            return self
        }
    }

    @discardableResult
    func verifySecurityScoreReviewsCount() -> Self {
        XCTContext.runActivity(named: "Verify number of reviews is displayed") { _ in
            waitAndAssertTrue(
                securityScoreReviewsCount,
                "Reviews count should be visible"
            )

            let reviewsText = securityScoreReviewsCount.label
            XCTAssertFalse(reviewsText.isEmpty, "Reviews count should not be empty")

            return self
        }
    }

    @discardableResult
    func verifySecurityScoreRatingStars() -> Self {
        XCTContext.runActivity(named: "Verify rating stars are visible") { _ in
            waitAndAssertTrue(
                securityScoreRatingStars,
                "Rating stars should be visible"
            )

            // Verify the rating stars have valid dimensions (are actually visible)
            XCTAssertTrue(
                securityScoreRatingStars.frame.width > 0 && securityScoreRatingStars.frame.height > 0,
                "Rating stars should have valid visible dimensions"
            )

            return self
        }
    }
}

enum MarketsTokenDetailsScreenElement: String, UIElement {
    case listedOnExchangesButton
    case securityScoreBlock
    case securityScoreValue
    case securityScoreRatingStars
    case securityScoreReviewsCount

    var accessibilityIdentifier: String {
        switch self {
        case .listedOnExchangesButton:
            MarketsAccessibilityIdentifiers.listedOnExchanges
        case .securityScoreBlock:
            MarketsAccessibilityIdentifiers.securityScoreBlock
        case .securityScoreValue:
            MarketsAccessibilityIdentifiers.securityScoreValue
        case .securityScoreRatingStars:
            MarketsAccessibilityIdentifiers.securityScoreRatingStars
        case .securityScoreReviewsCount:
            MarketsAccessibilityIdentifiers.securityScoreReviewsCount
        }
    }
}
