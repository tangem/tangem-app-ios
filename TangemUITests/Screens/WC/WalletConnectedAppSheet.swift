//
//  WalletConnectedAppSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class WalletConnectedAppSheet: ScreenBase<ConnectedAppScreenElement> {
    private lazy var headerTitle = staticText(.headerTitle)
    private lazy var disconnectButton = button(.disconnectButton)

    func waitForConnectedAppBottomSheetToBeVisible() -> Self {
        XCTContext.runActivity(named: "Validate Connected App sheet") { _ in
            waitAndAssertTrue(headerTitle, "Header title should be visible")
            XCTAssertTrue(disconnectButton.exists, "Disconnect button should be visible")
            XCTAssertTrue(disconnectButton.isHittable, "Disconnect button should be hittable")
            return self
        }
    }

    func tapDisconnectButton() -> WalletConnectionsScreen {
        XCTContext.runActivity(named: "Tap disconnect button") { _ in
            disconnectButton.waitAndTap()
            return WalletConnectionsScreen(app)
        }
    }
}

enum ConnectedAppScreenElement: UIElement {
    case headerTitle
    case disconnectButton

    var accessibilityIdentifier: String {
        switch self {
        case .headerTitle:
            return WalletConnectAccessibilityIdentifiers.headerTitle
        case .disconnectButton:
            return WalletConnectAccessibilityIdentifiers.disconnectButton
        }
    }
}
