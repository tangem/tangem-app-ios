//
//  ContextMenuScreen.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
import TangemAccessibilityIdentifiers

final class ContextMenuScreen: ScreenBase<ContextMenuScreenElement> {
    private lazy var analyticsButton = button(.analytics)
    private lazy var buyButton = button(.buy)
    private lazy var copyAddressButton = button(.copyAddress)
    private lazy var receiveButton = button(.receive)
    private lazy var sendButton = button(.send)
    private lazy var swapButton = button(.swap)
    private lazy var sellButton = button(.sell)
    private lazy var hideTokenButton = button(.hideToken)

    @discardableResult
    func waitForActionButtons() -> Self {
        XCTContext.runActivity(named: "Wait for context menu action buttons to exist") { _ in
            waitAndAssertTrue(buyButton, "Buy button should exist")
            XCTAssertTrue(copyAddressButton.exists, "Copy address button should exist")
            XCTAssertTrue(receiveButton.exists, "Receive button should exist")
            XCTAssertTrue(sendButton.exists, "Send button should exist")
            XCTAssertTrue(swapButton.exists, "Swap button should exist")
            XCTAssertTrue(analyticsButton.exists, "Analytics button should exist")
        }
        return self
    }

    func tapBuy() -> OnrampScreen {
        XCTContext.runActivity(named: "Tap Buy button in context menu") { _ in
            buyButton.waitAndTap()
            return OnrampScreen(app)
        }
    }

    func tapCopyAddress() -> Self {
        XCTContext.runActivity(named: "Tap Copy address button in context menu") { _ in
            copyAddressButton.waitAndTap()
            return self
        }
    }

    func tapReceive() -> NetworkSelectionWarningSheet {
        XCTContext.runActivity(named: "Tap Receive button in context menu") { _ in
            receiveButton.waitAndTap()
            return NetworkSelectionWarningSheet(app)
        }
    }

    @discardableResult
    func tapSend() -> SendScreen {
        XCTContext.runActivity(named: "Tap Send button in context menu") { _ in
            sendButton.waitAndTap()
            return SendScreen(app)
        }
    }

    func tapSwap() -> SwapStoriesScreen {
        XCTContext.runActivity(named: "Tap Swap button in context menu") { _ in
            swapButton.waitAndTap()
            return SwapStoriesScreen(app)
        }
    }

    func tapSell() -> MoonPayPage {
        XCTContext.runActivity(named: "Tap Sell button in context menu") { _ in
            sellButton.waitAndTap()
            return MoonPayPage(app)
        }
    }

    func tapAnalytics() -> MainScreen {
        XCTContext.runActivity(named: "Tap Analytics button in context menu") { _ in
            analyticsButton.waitAndTap()
            return MainScreen(app)
        }
    }

    func tapHideToken(tokenName: String) -> MainScreen {
        XCTContext.runActivity(named: "Tap Hide token button in context menu") { _ in
            hideTokenButton.waitAndTap()
            app.alerts["Hide \(tokenName)"].buttons["Hide"].waitAndTap()
            return MainScreen(app)
        }
    }

    @discardableResult
    func waitForAddressCopiedToast() -> Self {
        XCTContext.runActivity(named: "Wait for address copied toast to appear") { _ in
            let toast = app.staticTexts[ActionButtonsAccessibilityIdentifiers.addressCopiedToast]
            waitAndAssertTrue(toast, "Address copied toast should appear")
        }
        return self
    }

    @discardableResult
    func verifySellButtonDoesNotExist() -> Self {
        XCTContext.runActivity(named: "Verify Sell button does not exist in context menu") { _ in
            XCTAssertFalse(
                sellButton.waitForExistence(timeout: .conditional),
                "Sell button should not exist"
            )
        }
        return self
    }
}

enum ContextMenuScreenElement: String, UIElement {
    case analytics
    case buy
    case copyAddress
    case receive
    case send
    case swap
    case sell
    case hideToken

    var accessibilityIdentifier: String {
        switch self {
        case .analytics:
            return "Analytics"
        case .buy:
            return "Buy"
        case .copyAddress:
            return "Copy address"
        case .receive:
            return "Receive"
        case .send:
            return "Send"
        case .swap:
            return "Swap"
        case .sell:
            return "Sell"
        case .hideToken:
            return "Hide token"
        }
    }
}
