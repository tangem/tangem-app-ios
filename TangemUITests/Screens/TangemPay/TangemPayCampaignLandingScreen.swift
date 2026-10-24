//
//  TangemPayCampaignLandingScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayCampaignLandingScreen: ScreenBase<TangemPayCampaignLandingScreenElement> {
    private lazy var title = staticText(.campaignLandingTitle)
    private lazy var legalCaption = app.descendants(matching: .any)
        .matching(identifier: TangemPayAccessibilityIdentifiers.campaignLandingLegalCaption)
        .firstMatch
    private lazy var getCardButton = button(.campaignLandingGetCardButton)
    private lazy var closeButton = button(Localization.commonClose)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Tangem Pay campaign landing") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "Campaign landing title should be displayed")
            waitAndAssertTrue(getCardButton, "Get card button should be displayed on the campaign landing")
            return self
        }
    }

    @discardableResult
    func verifyContent() -> Self {
        XCTContext.runActivity(named: "Verify campaign landing title, benefits and Get card button") { _ in
            XCTAssertEqual(title.label, Localization.tangempayCampaignLandingTitle, "Campaign landing title should match")

            let benefits = Constants.benefitTexts.map { app.staticTexts[$0].firstMatch }
            for (benefit, text) in zip(benefits, Constants.benefitTexts) {
                waitAndAssertTrue(benefit, "Campaign benefit '\(text)' should be displayed")
            }

            for (upper, lower) in zip(benefits, benefits.dropFirst()) {
                XCTAssertLessThan(
                    upper.frame.minY,
                    lower.frame.minY,
                    "Campaign benefit '\(upper.label)' should be shown above '\(lower.label)'"
                )
            }

            XCTAssertEqual(
                getCardButton.label,
                Localization.tangempayOnboardingGetCardButtonText,
                "Campaign landing button should be 'Get card'"
            )
            return self
        }
    }

    @discardableResult
    func verifyCloseButton(exists: Bool) -> Self {
        XCTContext.runActivity(named: "Verify close button is \(exists ? "shown" : "hidden") on the campaign landing") { _ in
            if exists {
                waitAndAssertTrue(closeButton, "Close button should be displayed on the campaign landing")
            } else {
                XCTAssertFalse(closeButton.exists, "Close button should not be displayed on the campaign landing")
            }
            return self
        }
    }

    @discardableResult
    func verifyLegalCaption(exists: Bool) -> Self {
        XCTContext.runActivity(named: "Verify legal caption is \(exists ? "shown" : "hidden") on the campaign landing") { _ in
            guard exists else {
                XCTAssertFalse(legalCaption.exists, "Legal caption should not be displayed on the campaign landing")
                return self
            }

            waitAndAssertTrue(legalCaption, "Legal caption should be displayed on the campaign landing")
            XCTAssertTrue(
                legalCaption.label.contains(Localization.introductionTermsOfService),
                "Legal caption should mention the Terms of Service. Actual: '\(legalCaption.label)'"
            )
            XCTAssertTrue(
                legalCaption.label.contains(Localization.commonPrivacyPolicy),
                "Legal caption should mention the Privacy Policy. Actual: '\(legalCaption.label)'"
            )
            return self
        }
    }

    @discardableResult
    func tapGetCard() -> MainScreen {
        XCTContext.runActivity(named: "Tap Get card on the campaign landing") { _ in
            getCardButton.waitAndTap()
            XCTAssertTrue(
                title.waitForNonExistence(timeout: .networkRequest),
                "Campaign landing should close once the card is ordered"
            )
            return MainScreen(app)
        }
    }
}

private extension TangemPayCampaignLandingScreen {
    enum Constants {
        static let benefitTexts = [
            Localization.tangempayOnboardingSecurityTitle,
            Localization.tangempayOnboardingSecurityDescription,
            Localization.tangempayCampaignCashbackTitle,
            Localization.tangempayCampaignCashbackDescription,
            Localization.tangempayOnboardingPayTitle,
            Localization.tangempayCampaignSpendDescription,
        ]
    }
}

enum TangemPayCampaignLandingScreenElement: String, UIElement {
    case campaignLandingTitle
    case campaignLandingGetCardButton

    var accessibilityIdentifier: String {
        switch self {
        case .campaignLandingTitle:
            return TangemPayAccessibilityIdentifiers.campaignLandingTitle
        case .campaignLandingGetCardButton:
            return TangemPayAccessibilityIdentifiers.campaignLandingGetCardButton
        }
    }
}
