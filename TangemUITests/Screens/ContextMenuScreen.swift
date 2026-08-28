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

    static let derivedTokenActions: [ContextMenuScreenElement] = [
        .analytics, .copyAddress, .receive, .send, .swap, .buy, .hideToken,
    ]

    static let underivedTokenActions: [ContextMenuScreenElement] = [.hideToken]

    @discardableResult
    func assertActions(_ expected: [ContextMenuScreenElement], exact: Bool = true) -> Self {
        XCTContext.runActivity(named: "Assert context menu actions: \(expected.map(\.accessibilityIdentifier))") { _ in
            for action in expected {
                waitAndAssertTrue(button(action), "\(action.accessibilityIdentifier) button should exist")
            }

            if exact {
                let unexpected = ContextMenuScreenElement.allCases.filter { !expected.contains($0) }
                for action in unexpected {
                    XCTAssertFalse(
                        button(action).waitForExistence(timeout: .conditional),
                        "\(action.accessibilityIdentifier) button should not exist"
                    )
                }
            }
        }
        return self
    }

    @discardableResult
    func dismiss() -> MainScreen {
        XCTContext.runActivity(named: "Dismiss context menu") { _ in
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
            return MainScreen(app)
        }
    }

    @discardableResult
    func waitForActionButtons() -> Self {
        XCTContext.runActivity(named: "Wait for context menu action buttons to exist") { _ in
            waitAndAssertTrue(buyButton, "Buy button should exist")
            waitAndAssertTrue(copyAddressButton, "Copy address button should exist")
            waitAndAssertTrue(receiveButton, "Receive button should exist")
            waitAndAssertTrue(sendButton, "Send button should exist")
            waitAndAssertTrue(swapButton, "Swap button should exist")
            waitAndAssertTrue(analyticsButton, "Analytics button should exist")
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
    func tapHideTokenExpectingUnableAlert(tokenName: String) -> MainScreen {
        XCTContext.runActivity(named: "Tap Hide token and verify Unable to hide alert") { _ in
            hideTokenButton.waitAndTap()
            let alert = app.alerts["Unable to hide \(tokenName)"]
            waitAndAssertTrue(alert, "Unable to hide alert should appear")
            alert.buttons["OK"].waitAndTap()
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

enum ContextMenuScreenElement: String, UIElement, CaseIterable {
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
