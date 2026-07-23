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
    private lazy var receiveOptionButton = button(.receiveOption)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Add Funds sheet") { _ in
            waitAndAssertTrue(swapOptionButton, "Add Funds Swap option should be displayed")
            return self
        }
    }

    @discardableResult
    func verifySwapAndReceiveOptions() -> Self {
        XCTContext.runActivity(named: "Verify Add Funds sheet shows Swap and Receive options") { _ in
            waitAndAssertTrue(swapOptionButton, "Swap option should be displayed")
            waitAndAssertTrue(receiveOptionButton, "Receive option should be displayed")
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

    @discardableResult
    func tapReceive() -> ReceiveTokenAlertSheet {
        XCTContext.runActivity(named: "Tap Receive option on Add Funds sheet") { _ in
            receiveOptionButton.waitAndTap()
            return ReceiveTokenAlertSheet(app)
        }
    }
}

enum TangemPayAddFundsSheetElement: String, UIElement {
    case swapOption
    case receiveOption

    var accessibilityIdentifier: String {
        switch self {
        case .swapOption:
            TangemPayAccessibilityIdentifiers.addFundsSheetSwapOption
        case .receiveOption:
            TangemPayAccessibilityIdentifiers.addFundsSheetReceiveOption
        }
    }
}
