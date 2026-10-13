//
//  TangemPayVirtualAccountOnboardingScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayVirtualAccountOnboardingScreen: ScreenBase<TangemPayVirtualAccountOnboardingScreenElement> {
    private lazy var continueButton = button(.continueButton)
    private lazy var feeErrorBanner = button(.feeErrorBanner)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Virtual account onboarding screen") { _ in
            waitAndAssertTrue(continueButton, "Continue button should be displayed on Virtual account onboarding screen")
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
    func tapContinue() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Tap Continue to request a Virtual account") { _ in
            continueButton.waitAndTap()
            return TangemPayMainScreen(app)
        }
    }

    private func feeTitleText(_ fee: TangemPayAccessibilityIdentifiers.VirtualAccountFee) -> XCUIElement {
        app.staticTexts[TangemPayAccessibilityIdentifiers.virtualAccountFeeTitle(fee.rawValue)].firstMatch
    }

    private func feeValueText(_ fee: TangemPayAccessibilityIdentifiers.VirtualAccountFee) -> XCUIElement {
        app.staticTexts[TangemPayAccessibilityIdentifiers.virtualAccountFeeValue(fee.rawValue)].firstMatch
    }
}

enum TangemPayVirtualAccountOnboardingScreenElement: String, UIElement {
    case continueButton
    case feeErrorBanner

    var accessibilityIdentifier: String {
        switch self {
        case .continueButton:
            TangemPayAccessibilityIdentifiers.virtualAccountOnboardingContinueButton
        case .feeErrorBanner:
            TangemPayAccessibilityIdentifiers.virtualAccountFeeErrorBanner
        }
    }
}
