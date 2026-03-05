//
//  AccountSettingsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//

import XCTest
import TangemAccessibilityIdentifiers

final class AccountSettingsScreen: ScreenBase<AccountSettingsScreenElement> {
    private lazy var manageTokensButton = button(.manageTokenButton)

    func openManageTokens() -> ManageTokensScreen {
        XCTContext.runActivity(named: "Open Manage tokens (Account Settings)") { _ in
            manageTokensButton.waitAndTap()
            return ManageTokensScreen(app)
        }
    }

    func goBackToWalletSettings() -> CardSettingsScreen {
        XCTContext.runActivity(named: "Go back to Wallet settings") { _ in
            app.navigationBars.buttons["Wallet settings"].waitAndTap()
            return CardSettingsScreen(app)
        }
    }
}

enum AccountSettingsScreenElement: String, UIElement {
    case manageTokenButton

    var accessibilityIdentifier: String {
        switch self {
        case .manageTokenButton:
            return AccountsAccessibilityIdentifiers.accountDetailsManageTokensButton
        }
    }
}
