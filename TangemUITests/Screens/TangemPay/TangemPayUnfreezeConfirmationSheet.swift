//
//  TangemPayUnfreezeConfirmationSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayUnfreezeConfirmationSheet: ScreenBase<TangemPayUnfreezeConfirmationSheetElement> {
    private lazy var confirmButton = button(.confirmButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for unfreeze confirmation sheet") { _ in
            waitAndAssertTrue(confirmButton, "Unfreeze confirmation button should be displayed")
            return self
        }
    }

    @discardableResult
    func confirmUnfreeze() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Tap Unfreeze to confirm") { _ in
            confirmButton.waitAndTap()
            return TangemPayCardDetailsScreen(app)
        }
    }
}

enum TangemPayUnfreezeConfirmationSheetElement: String, UIElement {
    case confirmButton

    var accessibilityIdentifier: String {
        switch self {
        case .confirmButton:
            TangemPayAccessibilityIdentifiers.unfreezeSheetConfirmButton
        }
    }
}
