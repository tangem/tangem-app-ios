//
//  WalletConnectionsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class WalletConnectionsScreen: ScreenBase<WalletConnectionsScreenElement> {
    private lazy var headerTitle = staticText(.headerTitle)
    private lazy var newConnectionButton = button(.newConnectionButton)
    private lazy var noSessionsTitle = staticText(.noSessionsTitle)
    private lazy var noSessionsDescription = staticText(.noSessionsDescription)

    func validateEmptyState() {
        XCTContext.runActivity(named: "Validate WalletConnections empty state") { _ in
            XCTAssertTrue(noSessionsTitle.waitForExistence(timeout: .robustUIUpdate), "No sessions title should be visible")
            XCTAssertTrue(noSessionsDescription.exists, "No sessions description should be visible")
            XCTAssertTrue(newConnectionButton.exists, "New connection button should be visible")
        }
    }

    func tapNewConnection() -> WalletConnectSheet {
        XCTContext.runActivity(named: "Tap new connection button") { _ in
            newConnectionButton.waitAndTap()
            return WalletConnectSheet(app)
        }
    }

    func tapFirstDAppRow() -> ConnectedAppScreen {
        XCTContext.runActivity(named: "Tap first dApp row in connections list") { _ in
            let dAppRows = app.buttons.matching(identifier: WalletConnectAccessibilityIdentifiers.dAppRow)
            dAppRows.firstMatch.waitAndTap()
            return ConnectedAppScreen(app)
        }
    }
}

enum WalletConnectionsScreenElement: UIElement {
    case headerTitle
    case newConnectionButton
    case noSessionsTitle
    case noSessionsDescription

    var accessibilityIdentifier: String {
        switch self {
        case .headerTitle:
            return WalletConnectAccessibilityIdentifiers.headerTitle
        case .newConnectionButton:
            return WalletConnectAccessibilityIdentifiers.newConnectionButton
        case .noSessionsTitle:
            return WalletConnectAccessibilityIdentifiers.noSessionsTitle
        case .noSessionsDescription:
            return WalletConnectAccessibilityIdentifiers.noSessionsDescription
        }
    }
}
