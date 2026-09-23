//
//  TangemPayVirtualAccountBankDetailsSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayVirtualAccountBankDetailsSheet: ScreenBase<TangemPayVirtualAccountBankDetailsSheetElement> {
    private lazy var shareButton = button(.shareButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Virtual account banking details sheet") { _ in
            waitAndAssertTrue(shareButton, timeout: .networkRequest, "Share button should be displayed on banking details sheet")
            return self
        }
    }

    @discardableResult
    func verifyDetail(_ field: TangemPayVirtualAccountBankDetail, equals expectedValue: String) -> Self {
        XCTContext.runActivity(named: "Verify '\(field.rawValue)' equals '\(expectedValue)'") { _ in
            let value = detailValueText(field)
            waitAndAssertTrue(value, timeout: .networkRequest, "'\(field.rawValue)' value should be displayed")
            XCTAssertEqual(value.label, expectedValue, "'\(field.rawValue)' should be '\(expectedValue)'")
            return self
        }
    }

    @discardableResult
    func verifyDepositLimit() -> Self {
        XCTContext.runActivity(named: "Verify the daily deposit limit banner") { _ in
            let limitTitle = staticText(.depositLimitTitle)
            waitAndAssertTrue(limitTitle, "Deposit limit title should be displayed")
            XCTAssertEqual(limitTitle.label, Constants.depositLimitTitle, "Deposit limit title should match the design")

            let limitSubtitle = staticText(.depositLimitSubtitle)
            waitAndAssertTrue(limitSubtitle, "Deposit limit subtitle should be displayed")
            XCTAssertEqual(
                limitSubtitle.label,
                Constants.depositLimitSubtitle,
                "Deposit limit subtitle should match the design"
            )
            return self
        }
    }

    private func detailValueText(_ field: TangemPayVirtualAccountBankDetail) -> XCUIElement {
        app.staticTexts[TangemPayAccessibilityIdentifiers.virtualAccountBankDetailValue(field.rawValue)].firstMatch
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

enum TangemPayVirtualAccountBankDetailsSheetElement: String, UIElement {
    case shareButton
    case depositLimitTitle
    case depositLimitSubtitle

    var accessibilityIdentifier: String {
        switch self {
        case .shareButton:
            TangemPayAccessibilityIdentifiers.virtualAccountBankDetailsShareButton
        case .depositLimitTitle:
            TangemPayAccessibilityIdentifiers.virtualAccountDepositLimitTitle
        case .depositLimitSubtitle:
            TangemPayAccessibilityIdentifiers.virtualAccountDepositLimitSubtitle
        }
    }
}

private extension TangemPayVirtualAccountBankDetailsSheet {
    enum Constants {
        static let depositLimitTitle = "Available to deposit per day: $10,000"
        static let depositLimitSubtitle = "Limit is resetting every day"
    }
}
