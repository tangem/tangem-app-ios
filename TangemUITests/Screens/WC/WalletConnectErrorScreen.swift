//
//  WalletConnectErrorScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class WalletConnectErrorScreen: ScreenBase<WalletConnectErrorScreenElement> {
    private lazy var errorTitle = staticText(.errorTitle)
    private lazy var errorSubtitle = staticText(.errorSubtitle)
    private lazy var gotItButton = button(.gotItButton)

    @discardableResult
    func waitForErrorViewToBeVisible() -> Self {
        XCTContext.runActivity(named: "Wait for WC error view") { _ in
            waitAndAssertTrue(errorTitle, "Error view title should be visible")
            XCTAssertTrue(errorSubtitle.exists, "Error view subtitle should be visible")
            XCTAssertTrue(gotItButton.exists, "Got it button should be visible")
            return self
        }
    }

    @discardableResult
    func tapGotItButton() -> WalletConnectionsScreen {
        XCTContext.runActivity(named: "Tap Got it button") { _ in
            gotItButton.waitAndTap()
            return WalletConnectionsScreen(app)
        }
    }
}

enum WalletConnectErrorScreenElement: UIElement {
    case errorTitle
    case errorSubtitle
    case gotItButton

    var accessibilityIdentifier: String {
        switch self {
        case .errorTitle:
            return WalletConnectAccessibilityIdentifiers.errorViewTitle
        case .errorSubtitle:
            return WalletConnectAccessibilityIdentifiers.errorViewSubtitle
        case .gotItButton:
            return WalletConnectAccessibilityIdentifiers.errorViewGotItButton
        }
    }
}
