//
//  TangemPayAddFundsSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayAddFundsSheet: ScreenBase<TangemPayAddFundsSheetElement> {
    private lazy var swapOptionButton = button(.swapOption)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Add Funds sheet") { _ in
            waitAndAssertTrue(swapOptionButton, "Add Funds Swap option should be displayed")
            return self
        }
    }

    @discardableResult
    func tapSwap() -> SwapScreen {
        XCTContext.runActivity(named: "Tap Swap option on Add Funds sheet") { _ in
            swapOptionButton.waitAndTap()
            return SwapScreen(app)
        }
    }
}

enum TangemPayAddFundsSheetElement: String, UIElement {
    case swapOption

    var accessibilityIdentifier: String {
        switch self {
        case .swapOption:
            TangemPayAccessibilityIdentifiers.addFundsSheetSwapOption
        }
    }
}
