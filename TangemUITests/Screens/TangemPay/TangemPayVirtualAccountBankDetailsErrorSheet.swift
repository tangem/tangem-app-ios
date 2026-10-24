//
//  TangemPayVirtualAccountBankDetailsErrorSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayVirtualAccountBankDetailsErrorSheet: ScreenBase<TangemPayVirtualAccountBankDetailsErrorSheetElement> {
    private lazy var icon = app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.popupIcon].firstMatch
    private lazy var title = app.staticTexts[Localization.tangempayVaBankingDetailsErrorTitle].firstMatch
    private lazy var descriptionText = app.staticTexts[Localization.tangempayVaBankingDetailsErrorDescription].firstMatch
    private lazy var retryButton = button(.retryButton)
    private lazy var contactSupportButton = button(.contactSupportButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for banking details error sheet") { _ in
            waitAndAssertTrue(retryButton, timeout: .networkRequest, "Retry button should be displayed on the error sheet")
            return self
        }
    }

    @discardableResult
    func verifySheetContent() -> Self {
        XCTContext.runActivity(named: "Verify banking details error sheet content") { _ in
            waitAndAssertTrue(icon, "Warning icon should be displayed")
            waitAndAssertTrue(title, "Sheet title '\(Localization.tangempayVaBankingDetailsErrorTitle)' should be displayed")
            waitAndAssertTrue(descriptionText, "Sheet description '\(Localization.tangempayVaBankingDetailsErrorDescription)' should be displayed")
            // The mail composer is a system screen, so the support path is covered up to the button.
            waitAndAssertTrue(contactSupportButton, "Contact support button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapRetry() -> TangemPayVirtualAccountDetailsScreen {
        XCTContext.runActivity(named: "Tap Retry to request banking details again") { _ in
            retryButton.waitAndTap()
            return TangemPayVirtualAccountDetailsScreen(app)
        }
    }
}

enum TangemPayVirtualAccountBankDetailsErrorSheetElement: String, UIElement {
    case retryButton
    case contactSupportButton

    var accessibilityIdentifier: String {
        switch self {
        case .retryButton:
            TangemPayAccessibilityIdentifiers.virtualAccountBankDetailsErrorRetryButton
        case .contactSupportButton:
            TangemPayAccessibilityIdentifiers.popupSecondaryButton
        }
    }
}
