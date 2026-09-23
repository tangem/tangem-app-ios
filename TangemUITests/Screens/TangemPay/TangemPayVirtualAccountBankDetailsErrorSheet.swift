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
    private lazy var title = app.staticTexts[Constants.title].firstMatch
    private lazy var descriptionText = app.staticTexts[Constants.description].firstMatch
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
            waitAndAssertTrue(title, "Sheet title '\(Constants.title)' should be displayed")
            waitAndAssertTrue(descriptionText, "Sheet description '\(Constants.description)' should be displayed")
            // The mail composer is a system screen, so the support path is covered up to the button.
            waitAndAssertTrue(contactSupportButton, "Contact support button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapRetry() -> TangemPayVirtualAccountBankDetailsSheet {
        XCTContext.runActivity(named: "Tap Retry to request banking details again") { _ in
            retryButton.waitAndTap()
            return TangemPayVirtualAccountBankDetailsSheet(app)
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

private extension TangemPayVirtualAccountBankDetailsErrorSheet {
    enum Constants {
        static let title = "Couldn't load banking details"
        static let description = "Please try again or contact support if the issue persists"
    }
}
