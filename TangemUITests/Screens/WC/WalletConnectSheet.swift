//
//  WalletConnectSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class WalletConnectSheet: ScreenBase<WalletConnectConnectionScreenElement> {
    private lazy var headerTitle = staticText(.headerTitle)
    private lazy var providerName = staticText(.providerName)
    private lazy var connectionRequestLabel = staticText(.connectionRequestLabel)
    private lazy var walletLabel = button(.walletLabel)
    private lazy var networksLabel = button(.networksLabel)
    private lazy var cancelButton = button(.cancelButton)
    private lazy var connectButton = button(.connectButton)

    @discardableResult
    func waitForConnectionProposalBottomSheetToBeVisible() -> Self {
        XCTContext.runActivity(named: "Validate WalletConnect connection sheet elements") { _ in
            waitAndAssertTrue(
                headerTitle,
                "Header title 'WalletConnect' should be visible"
            )
            waitAndAssertTrue(
                providerName,
                "Provider name should be visible and contain dApp information"
            )
            waitAndAssertTrue(
                connectionRequestLabel,
                "Connection request label should be visible"
            )
            waitAndAssertTrue(
                walletLabel,
                "Wallet label should be visible"
            )
            waitAndAssertTrue(
                networksLabel,
                "Networks label should be visible"
            )
            waitAndAssertTrue(
                cancelButton,
                "Cancel button should be visible"
            )
            XCTAssertTrue(
                cancelButton.isHittable,
                "Cancel button should be hittable"
            )
            waitAndAssertTrue(
                connectButton,
                "Connect button should be visible"
            )
            XCTAssertTrue(
                connectButton.isHittable,
                "Connect button should be hittable"
            )
            return self
        }
    }

    func rejectConnection() {
        XCTContext.runActivity(named: "Reject WalletConnect connection") { _ in
            cancelButton.waitAndTap()
        }
    }

    func tapConnectionButton() {
        XCTContext.runActivity(named: "Approve WalletConnect connection") { _ in
            connectButton.waitAndTap()
        }
    }
}

enum WalletConnectConnectionScreenElement: String, UIElement {
    case headerTitle
    case providerName
    case connectionRequestLabel
    case walletLabel
    case networksLabel
    case cancelButton
    case connectButton

    var accessibilityIdentifier: String {
        switch self {
        case .headerTitle:
            WalletConnectAccessibilityIdentifiers.headerTitle
        case .providerName:
            CommonUIAccessibilityIdentifiers.entityProviderName
        case .connectionRequestLabel:
            WalletConnectAccessibilityIdentifiers.connectionRequestLabel
        case .walletLabel:
            WalletConnectAccessibilityIdentifiers.walletLabel
        case .networksLabel:
            WalletConnectAccessibilityIdentifiers.networksLabel
        case .cancelButton:
            WalletConnectAccessibilityIdentifiers.cancelButton
        case .connectButton:
            WalletConnectAccessibilityIdentifiers.connectButton
        }
    }
}
