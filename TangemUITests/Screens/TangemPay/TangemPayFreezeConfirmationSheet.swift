//
//  TangemPayFreezeConfirmationSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayFreezeConfirmationSheet: ScreenBase<TangemPayFreezeConfirmationSheetElement> {
    private lazy var confirmButton = button(.confirmButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for freeze confirmation sheet") { _ in
            waitAndAssertTrue(confirmButton, "Freeze confirmation button should be displayed")
            return self
        }
    }

    @discardableResult
    func confirmFreeze() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Tap Freeze to confirm") { _ in
            confirmButton.waitAndTap()
            return TangemPayCardDetailsScreen(app)
        }
    }
}

enum TangemPayFreezeConfirmationSheetElement: String, UIElement {
    case confirmButton

    var accessibilityIdentifier: String {
        switch self {
        case .confirmButton:
            TangemPayAccessibilityIdentifiers.freezeSheetConfirmButton
        }
    }
}
