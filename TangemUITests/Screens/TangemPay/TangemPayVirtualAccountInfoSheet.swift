//
//  TangemPayVirtualAccountInfoSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayVirtualAccountInfoSheet: ScreenBase<TangemPayVirtualAccountInfoSheetElement> {
    private lazy var showDetailsButton = button(.showDetailsButton)
    private lazy var feeErrorBanner = button(.feeErrorBanner)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Virtual account info sheet") { _ in
            waitAndAssertTrue(showDetailsButton, "Show details button should be displayed on Virtual account info sheet")
            return self
        }
    }

    @discardableResult
    func verifyFeeValue(_ fee: TangemPayAccessibilityIdentifiers.VirtualAccountFee, equals expectedValue: String) -> Self {
        XCTContext.runActivity(named: "Verify '\(fee.rawValue)' fee equals '\(expectedValue)'") { _ in
            let value = feeValueText(fee)
            waitAndAssertTrue(value, timeout: .networkRequest, "'\(fee.rawValue)' fee value should be displayed")
            XCTAssertEqual(value.label, expectedValue, "'\(fee.rawValue)' fee should be '\(expectedValue)'")
            return self
        }
    }

    @discardableResult
    func verifyFeeNotDisplayed(_ fee: TangemPayAccessibilityIdentifiers.VirtualAccountFee) -> Self {
        XCTContext.runActivity(named: "Verify '\(fee.rawValue)' fee is not displayed") { _ in
            // Both rows are rendered while the fees are still loading, so the wait has to outlast the request.
            XCTAssertTrue(
                feeTitleText(fee).waitForNonExistence(timeout: .networkRequest),
                "'\(fee.rawValue)' fee row should not be displayed"
            )
            return self
        }
    }

    @discardableResult
    func verifyFeeErrorDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify fee error banner is displayed") { _ in
            waitAndAssertTrue(feeErrorBanner, timeout: .networkRequest, "Fee error banner should be displayed")
            return self
        }
    }

    @discardableResult
    func tapFeeErrorBanner() -> Self {
        XCTContext.runActivity(named: "Tap fee error banner to reload fees") { _ in
            feeErrorBanner.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapShowDetailsExpectingSuccess() -> TangemPayVirtualAccountSuccessScreen {
        XCTContext.runActivity(named: "Tap Show details to create a Virtual account order") { _ in
            tapShowDetails()
            return TangemPayVirtualAccountSuccessScreen(app)
        }
    }

    @discardableResult
    func tapShowDetailsExpectingBankDetails() -> TangemPayVirtualAccountBankDetailsSheet {
        XCTContext.runActivity(named: "Tap Show details to open Virtual account banking details") { _ in
            tapShowDetails()
            return TangemPayVirtualAccountBankDetailsSheet(app)
        }
    }

    @discardableResult
    func tapShowDetailsExpectingError() -> TangemPayVirtualAccountBankDetailsErrorSheet {
        XCTContext.runActivity(named: "Tap Show details expecting the banking details error sheet") { _ in
            tapShowDetails()
            return TangemPayVirtualAccountBankDetailsErrorSheet(app)
        }
    }

    private func tapShowDetails() {
        showDetailsButton.waitAndTap()
        XCTAssertTrue(
            showDetailsButton.waitForNonExistence(timeout: .networkRequest),
            "Virtual account info sheet should be dismissed after tapping Show details"
        )
    }

    private func feeTitleText(_ fee: TangemPayAccessibilityIdentifiers.VirtualAccountFee) -> XCUIElement {
        app.staticTexts[TangemPayAccessibilityIdentifiers.virtualAccountFeeTitle(fee)].firstMatch
    }

    private func feeValueText(_ fee: TangemPayAccessibilityIdentifiers.VirtualAccountFee) -> XCUIElement {
        app.staticTexts[TangemPayAccessibilityIdentifiers.virtualAccountFeeValue(fee)].firstMatch
    }
}

enum TangemPayVirtualAccountInfoSheetElement: String, UIElement {
    case showDetailsButton
    case feeErrorBanner

    var accessibilityIdentifier: String {
        switch self {
        case .showDetailsButton:
            TangemPayAccessibilityIdentifiers.virtualAccountShowDetailsButton
        case .feeErrorBanner:
            TangemPayAccessibilityIdentifiers.virtualAccountFeeErrorBanner
        }
    }
}
