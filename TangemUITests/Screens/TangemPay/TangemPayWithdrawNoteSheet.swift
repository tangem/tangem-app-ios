//
//  TangemPayWithdrawNoteSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayWithdrawNoteSheet: ScreenBase<TangemPayWithdrawNoteSheetElement> {
    private lazy var primaryButton = button(.primaryButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Withdraw note sheet") { _ in
            waitAndAssertTrue(primaryButton, "Withdraw note sheet primary button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapGotIt() -> SwapScreen {
        XCTContext.runActivity(named: "Tap Got it on Withdraw note sheet") { _ in
            primaryButton.waitAndTap()
            return SwapScreen(app)
        }
    }
}

enum TangemPayWithdrawNoteSheetElement: String, UIElement {
    case primaryButton

    var accessibilityIdentifier: String {
        switch self {
        case .primaryButton:
            TangemPayAccessibilityIdentifiers.withdrawNoteSheetPrimaryButton
        }
    }
}
