//
//  WelcomeBackScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class WelcomeBackScreen: ScreenBase<WelcomeBackScreenElement> {
    private lazy var title = staticText(.title)
    private lazy var subtitle = staticText(.subtitle)
    private lazy var addWalletButton = button(.addWalletButton)
    private lazy var walletsList = otherElement(.walletsList)
    private lazy var biometricsUnlockButton = button(.biometricsUnlockButton)

    @discardableResult
    func validateScreen() -> Self {
        XCTContext.runActivity(named: "Validate Welcome Back screen is displayed") { _ in
            waitAndAssertTrue(title, "Title should be displayed")
            waitAndAssertTrue(subtitle, "Subtitle should be displayed")
            waitAndAssertTrue(addWalletButton, "Add wallet button should be displayed")
            waitAndAssertTrue(walletsList, "Wallets list should be displayed")
        }
        return self
    }

    @discardableResult
    func selectWalletByName(_ walletName: String) -> Self {
        XCTContext.runActivity(named: "Select wallet by name: \(walletName)") { _ in
            let walletItemIdentifier = AuthAccessibilityIdentifiers.walletItem(walletName: walletName)
            let walletButton = app.buttons[walletItemIdentifier].firstMatch

            waitAndAssertTrue(walletButton, "Wallet button with name '\(walletName)' should exist")
            walletButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func tapAddWallet() -> Self {
        XCTContext.runActivity(named: "Tap Add wallet button") { _ in
            waitAndAssertTrue(addWalletButton, "Add wallet button should exist")
            addWalletButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func tapBiometricsUnlock() -> Self {
        XCTContext.runActivity(named: "Tap biometrics unlock button") { _ in
            waitAndAssertTrue(biometricsUnlockButton, "Biometrics unlock button should exist")
            biometricsUnlockButton.waitAndTap()
        }
        return self
    }

    @discardableResult
    func waitForWalletExists(_ walletName: String) -> Self {
        XCTContext.runActivity(named: "Wait for wallet '\(walletName)' to exist") { _ in
            let walletItemIdentifier = AuthAccessibilityIdentifiers.walletItem(walletName: walletName)
            let walletButton = app.buttons[walletItemIdentifier].firstMatch
            waitAndAssertTrue(walletButton, "Wallet '\(walletName)' should exist")
        }
        return self
    }
}

enum WelcomeBackScreenElement: String, UIElement {
    case title
    case subtitle
    case addWalletButton
    case walletsList
    case biometricsUnlockButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return AuthAccessibilityIdentifiers.title
        case .subtitle:
            return AuthAccessibilityIdentifiers.subtitle
        case .addWalletButton:
            return AuthAccessibilityIdentifiers.addWalletButton
        case .walletsList:
            return AuthAccessibilityIdentifiers.walletsList
        case .biometricsUnlockButton:
            return AuthAccessibilityIdentifiers.biometricsUnlockButton
        }
    }
}
