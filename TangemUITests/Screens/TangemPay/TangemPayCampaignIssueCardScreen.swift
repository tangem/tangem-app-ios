//
//  TangemPayCampaignIssueCardScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayCampaignIssueCardScreen: ScreenBase<TangemPayCampaignIssueCardScreenElement> {
    private lazy var title = app.staticTexts[Localization.tangempayCampaignIssueCardTitle].firstMatch
    private lazy var virtualBadge = app.staticTexts[Localization.tangempayOrderTypeSegmentVirtual].firstMatch
    private lazy var issueButton = button(.campaignIssueCardButton)
    private lazy var closeButton = button(Localization.commonClose)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Tangem Pay 'Issue special card' screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "'Issue special card' title should be displayed")
            waitAndAssertTrue(issueButton, "Issue button should be displayed on the 'Issue special card' screen")
            return self
        }
    }

    @discardableResult
    func verifyContent(feeValue: String) -> Self {
        XCTContext.runActivity(named: "Verify 'Issue special card' content with fee '\(feeValue)'") { _ in
            waitAndAssertTrue(virtualBadge, "Virtual badge should be displayed")
            verifyOfferInfoRow(.issueFee, contains: [Localization.tangempayOrderTypeIssueFee, feeValue])
            verifyOfferInfoRow(
                .issueTime,
                contains: [Localization.tangempayCampaignIssueTime, Localization.tangempayOrderTypeDeliveryTimeInstant]
            )
            XCTAssertEqual(issueButton.label, Localization.tangempayCampaignIssueButton, "Issue button title should match")
            XCTAssertTrue(issueButton.waitForState(state: .enabled), "Issue button should be enabled")
            waitAndAssertTrue(closeButton, "Close button should be displayed on the 'Issue special card' screen")
            return self
        }
    }

    @discardableResult
    func tapIssue() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Tap Issue on the 'Issue special card' screen") { _ in
            issueButton.waitAndTap()
            XCTAssertTrue(
                title.waitForNonExistence(timeout: .networkRequest),
                "'Issue special card' screen should close once the card is ordered"
            )
            return TangemPayMainScreen(app)
        }
    }
}

enum TangemPayCampaignIssueCardScreenElement: String, UIElement {
    case campaignIssueCardButton

    var accessibilityIdentifier: String {
        switch self {
        case .campaignIssueCardButton:
            return TangemPayAccessibilityIdentifiers.campaignIssueCardButton
        }
    }
}
