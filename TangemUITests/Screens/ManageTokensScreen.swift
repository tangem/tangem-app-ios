//
//  ManageTokensScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//

import XCTest
import TangemAccessibilityIdentifiers

final class ManageTokensScreen: ScreenBase<ManageTokensScreenElement> {
    @discardableResult
    func expandTokenIfNeeded(_ tokenName: String) -> Self {
        XCTContext.runActivity(named: "Expand token if needed: \(tokenName)") { _ in
            let tokenLabel = app.staticTexts[tokenName]
            tokenLabel.waitAndTap()
            return self
        }
    }

    @discardableResult
    func ensureNetworkSelected(_ networkName: String) -> Self {
        XCTContext.runActivity(named: "Ensure network selected: \(networkName)") { _ in
            let networkText = app.staticTexts[networkName]
            waitAndAssertTrue(networkText, "Network row should exist: \(networkName)")

            let toggleIdentifier = ManageTokensAccessibilityIdentifiers.networkToggle(networkName)
            let toggle = app.switches[toggleIdentifier]
            waitAndAssertTrue(toggle, "Network toggle \(toggleIdentifier) should exist")

            if (toggle.value as? String) == "0" {
                toggle.waitAndTap()
            }

            return self
        }
    }

    @discardableResult
    func longPressNetworkToCopy(_ networkName: String, duration: TimeInterval = 1.0) -> Self {
        XCTContext.runActivity(named: "Long press \(networkName) to copy") { _ in
            let networkText = app.staticTexts[networkName]
            waitAndAssertTrue(networkText, "Network row should exist: \(networkName)")
            networkText.press(forDuration: duration)
            return self
        }
    }

    func goBackToWalletSettings() -> CardSettingsScreen {
        XCTContext.runActivity(named: "Go back to Wallet settings") { _ in
            app.navigationBars.buttons["Wallet settings"].waitAndTap()
        }

        return CardSettingsScreen(app)
    }
}

enum ManageTokensScreenElement: String, UIElement {
    case none = ""
}
