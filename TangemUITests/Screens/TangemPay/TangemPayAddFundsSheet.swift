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
    private lazy var closeButton = button(.closeButton)

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

    @discardableResult
    func tapReceiveExpectingChooseNetwork() -> TangemPayChooseNetworkSheet {
        XCTContext.runActivity(named: "Tap Receive option expecting the Choose network sheet") { _ in
            receiveOptionButton.waitAndTap()
            return TangemPayChooseNetworkSheet(app)
        }
    }

    @discardableResult
    func verifyOptionsOrder() -> Self {
        XCTContext.runActivity(named: "Verify Add Funds options are ordered bank transfer, swap, receive") { _ in
            waitAndAssertTrue(bankTransferOptionButton, "Bank transfer option should be displayed")
            waitAndAssertTrue(swapOptionButton, "Swap option should be displayed")
            waitAndAssertTrue(receiveOptionButton, "Receive option should be displayed")

            XCTAssertTrue(
                bankTransferOptionButton.frame.minY < swapOptionButton.frame.minY,
                "Bank transfer option should be listed above the Swap option"
            )
            XCTAssertTrue(
                swapOptionButton.frame.minY < receiveOptionButton.frame.minY,
                "Swap option should be listed above the Receive option"
            )
            return self
        }
    }

    @discardableResult
    func verifyOptionLabels(bankTransfer: [String], swap: [String], receive: [String]) -> Self {
        XCTContext.runActivity(named: "Verify Add Funds option titles and subtitles") { _ in
            verifyLabel(of: bankTransferOptionButton, contains: bankTransfer, name: "Bank transfer")
            verifyLabel(of: swapOptionButton, contains: swap, name: "Swap")
            verifyLabel(of: receiveOptionButton, contains: receive, name: "Receive")
            return self
        }
    }

    @discardableResult
    func close() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Close the Add Funds sheet") { _ in
            closeButton.waitAndTap()
            XCTAssertTrue(swapOptionButton.waitForNonExistence(timeout: .robustUIUpdate), "Add Funds sheet should be closed")
            return TangemPayMainScreen(app)
        }
    }

    private func verifyLabel(of element: XCUIElement, contains texts: [String], name: String) {
        waitAndAssertTrue(element, "\(name) option should be displayed")
        for text in texts {
            XCTAssertTrue(
                element.label.contains(text),
                "\(name) option should carry '\(text)'. Actual: '\(element.label)'"
            )
        }
    }
}

enum TangemPayAddFundsSheetElement: String, UIElement {
    case swapOption
    case receiveOption
    case bankTransferOption
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .swapOption:
            TangemPayAccessibilityIdentifiers.addFundsSheetSwapOption
        case .receiveOption:
            TangemPayAccessibilityIdentifiers.addFundsSheetReceiveOption
        case .bankTransferOption:
            TangemPayAccessibilityIdentifiers.addFundsSheetBankTransferOption
        case .closeButton:
            TangemPayAccessibilityIdentifiers.addFundsSheetCloseButton
        }
    }
}
