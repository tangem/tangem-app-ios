//
//  TangemPayBankTransferConfirmScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayBankTransferConfirmScreen: ScreenBase<TangemPayBankTransferConfirmScreenElement> {
    private lazy var sendButton = button(.sendButton)
    private lazy var title = app.staticTexts[Localization.tangempayWithdrawBankConfirmTitle].firstMatch

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Confirm transfer") { _ in
            waitAndAssertTrue(sendButton, timeout: .networkRequest, "Send button should be displayed")
            waitAndAssertTrue(title, "Screen should be titled '\(Localization.tangempayWithdrawBankConfirmTitle)'")
            return self
        }
    }

    @discardableResult
    func verifyRecipientDetails(_ values: [String]) -> Self {
        XCTContext.runActivity(named: "Verify the recipient details \(values)") { _ in
            for value in values {
                let predicate = NSPredicate(
                    format: "identifier == %@ AND label CONTAINS %@",
                    TangemPayBankTransferConfirmScreenElement.section.accessibilityIdentifier,
                    value
                )
                waitAndAssertTrue(
                    app.descendants(matching: .any).matching(predicate).firstMatch,
                    "Confirm transfer should show '\(value)'"
                )
            }
            return self
        }
    }

    @discardableResult
    func tapSend() -> TangemPayBankTransferSuccessScreen {
        XCTContext.runActivity(named: "Tap Send") { _ in
            XCTAssertTrue(sendButton.waitForState(state: .enabled, for: .conditional), "Send should be enabled")
            sendButton.waitAndTap()
            return TangemPayBankTransferSuccessScreen(app)
        }
    }
}

enum TangemPayBankTransferConfirmScreenElement: String, UIElement {
    case section
    case sendButton

    var accessibilityIdentifier: String {
        switch self {
        case .section:
            TangemPayOfframpAccessibilityIdentifiers.confirmSection
        case .sendButton:
            TangemPayOfframpAccessibilityIdentifiers.confirmSendButton
        }
    }
}
