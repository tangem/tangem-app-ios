//
//  TangemPayBankTransferAmountScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayBankTransferAmountScreen: ScreenBase<TangemPayBankTransferAmountScreenElement> {
    private lazy var amountField = textField(.amountField)
    private lazy var tokenRow = button(.tokenRow)
    private lazy var continueButton = button(.continueButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for the bank transfer amount screen") { _ in
            waitAndAssertTrue(amountField, timeout: .networkRequest, "Amount field should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyTitle(_ title: String) -> Self {
        XCTContext.runActivity(named: "Verify the amount screen title '\(title)'") { _ in
            waitAndAssertTrue(app.staticTexts[title].firstMatch, "Amount screen should be titled '\(title)'")
            return self
        }
    }

    @discardableResult
    func verifySourceToken(symbol: String, network: String) -> Self {
        XCTContext.runActivity(named: "Verify the source token is \(symbol) on \(network)") { _ in
            waitAndAssertTrue(tokenRow, timeout: .networkRequest, "Source token row should be displayed")
            for text in [symbol, network] {
                XCTAssertTrue(tokenRow.label.contains(text), "Source token should mention '\(text)'. Actual: '\(tokenRow.label)'")
            }
            return self
        }
    }

    @discardableResult
    func tapSourceToken() -> TangemPayBankTransferTokenSheet {
        XCTContext.runActivity(named: "Open the source token selector") { _ in
            tokenRow.waitAndTap()
            return TangemPayBankTransferTokenSheet(app).waitForSheet()
        }
    }

    @discardableResult
    func enterAmount(_ amount: String) -> Self {
        XCTContext.runActivity(named: "Enter amount '\(amount)'") { _ in
            waitAndAssertTrue(amountField, "Amount field should be displayed")
            amountField.tap()
            amountField.typeText(amount)
            XCTAssertTrue(
                amountField.waitForValue(where: { $0.contains(amount) }),
                "Amount field should contain '\(amount)'. Actual: '\(amountField.getValue())'"
            )
            return self
        }
    }

    @discardableResult
    func tapContinueToTransferType() -> TangemPayBankTransferWizardScreen {
        tapContinue()
        return TangemPayBankTransferWizardScreen(app)
    }

    @discardableResult
    func tapContinueToConfirmation() -> TangemPayBankTransferConfirmScreen {
        tapContinue()
        return TangemPayBankTransferConfirmScreen(app).waitForScreen()
    }

    @discardableResult
    func close() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Close the bank transfer") { _ in
            guard let closeButton = app.buttons.matching(NSPredicate(format: "label == %@", Localization.commonClose)).firstHittableElement() else {
                XCTFail("Bank transfer Close button should become hittable")
                return TangemPayMainScreen(app)
            }
            closeButton.tap()
            XCTAssertTrue(amountField.waitForNonExistence(timeout: .conditional), "Bank transfer should be dismissed")
            return TangemPayMainScreen(app).waitForScreen()
        }
    }

    private func tapContinue() {
        XCTContext.runActivity(named: "Tap Continue on the amount screen") { _ in
            XCTAssertTrue(continueButton.waitForState(state: .enabled, for: .conditional), "Continue should be enabled")
            continueButton.waitAndTap()
        }
    }
}

enum TangemPayBankTransferAmountScreenElement: String, UIElement {
    case amountField
    case tokenRow
    case continueButton

    var accessibilityIdentifier: String {
        switch self {
        case .amountField:
            TangemPayOfframpAccessibilityIdentifiers.amountField
        case .tokenRow:
            TangemPayOfframpAccessibilityIdentifiers.amountTokenRow
        case .continueButton:
            TangemPayOfframpAccessibilityIdentifiers.amountContinueButton
        }
    }
}
