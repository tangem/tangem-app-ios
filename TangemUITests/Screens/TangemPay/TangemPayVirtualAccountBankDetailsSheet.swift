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

    var accessibilityIdentifier: String {
        switch self {
        case .shareButton:
            TangemPayAccessibilityIdentifiers.virtualAccountBankDetailsShareButton
        }
    }
}
