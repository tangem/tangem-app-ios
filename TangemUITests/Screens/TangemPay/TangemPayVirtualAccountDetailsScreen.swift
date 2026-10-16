//
//  TangemPayVirtualAccountDetailsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayVirtualAccountDetailsScreen: ScreenBase<TangemPayVirtualAccountDetailsScreenElement> {
    private lazy var shareButton = button(.shareButton)
    private lazy var depositLimitHint = staticText(.depositLimitHint)
    private lazy var dailyDepositsTitle = app.staticTexts[Localization.tangempayBankTransferDetailsDailyDeposits].firstMatch

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Virtual account details screen") { _ in
            waitAndAssertTrue(shareButton, timeout: .networkRequest, "Share button should be displayed on Virtual account details screen")
            return self
        }
    }

    @discardableResult
    func verifyDetail(_ field: TangemPayVirtualAccountBankDetail, equals expectedValue: String) -> Self {
        XCTContext.runActivity(named: "Verify '\(field.rawValue)' equals '\(expectedValue)'") { _ in
            let row = app.buttons[TangemPayAccessibilityIdentifiers.virtualAccountBankDetailCopyButton(field.rawValue)].firstMatch
            waitAndAssertTrue(row, timeout: .networkRequest, "'\(field.rawValue)' row should be displayed")
            XCTAssertTrue(row.label.contains(expectedValue), "'\(field.rawValue)' row should show '\(expectedValue)', but was '\(row.label)'")
            return self
        }
    }

    @discardableResult
    func verifyDepositLimit(_ limit: String) -> Self {
        XCTContext.runActivity(named: "Verify the daily deposit limit '\(limit)'") { _ in
            waitAndAssertTrue(dailyDepositsTitle, "Daily deposits row should be displayed")
            waitAndAssertTrue(app.staticTexts[limit].firstMatch, "Daily deposit limit '\(limit)' should be displayed")
            waitAndAssertTrue(depositLimitHint, "Daily deposit limit hint should be displayed")
            XCTAssertEqual(
                depositLimitHint.label,
                Localization.tangempayBankTransferDetailsDailyDepositsHint(limit),
                "Daily deposit limit hint should name the limit"
            )
            return self
        }
    }
}

enum TangemPayVirtualAccountBankDetail: String {
    case beneficiaryName = "beneficiary_name"
    case beneficiaryAddress = "beneficiary_address"
    case bankName = "bank_name"
    case bankAddress = "bank_address"
    case accountNumber = "account_number"
    case routingNumber = "routing_number"
}

enum TangemPayVirtualAccountDetailsScreenElement: String, UIElement {
    case shareButton
    case depositLimitHint

    var accessibilityIdentifier: String {
        switch self {
        case .shareButton:
            TangemPayAccessibilityIdentifiers.virtualAccountBankDetailsShareButton
        case .depositLimitHint:
            TangemPayAccessibilityIdentifiers.virtualAccountDepositLimitSubtitle
        }
    }
}
