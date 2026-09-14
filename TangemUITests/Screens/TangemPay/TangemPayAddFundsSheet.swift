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
    private lazy var bankTransferOptionButton = button(.bankTransferOption)

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
    func verifyBankTransferOptionDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify Add Funds sheet shows Bank transfer option") { _ in
            waitAndAssertTrue(bankTransferOptionButton, "Bank transfer option should be displayed")
            return self
        }
    }

    @discardableResult
    func tapBankTransfer() -> TangemPayVirtualAccountInfoSheet {
        XCTContext.runActivity(named: "Tap Bank transfer option on Add Funds sheet") { _ in
            bankTransferOptionButton.waitAndTap()
            return TangemPayVirtualAccountInfoSheet(app)
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
    case bankTransferOption

    var accessibilityIdentifier: String {
        switch self {
        case .swapOption:
            TangemPayAccessibilityIdentifiers.addFundsSheetSwapOption
        case .receiveOption:
            TangemPayAccessibilityIdentifiers.addFundsSheetReceiveOption
        case .bankTransferOption:
            TangemPayAccessibilityIdentifiers.addFundsSheetBankTransferOption
        }
    }
}
