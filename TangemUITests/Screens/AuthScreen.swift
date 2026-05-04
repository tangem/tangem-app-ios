//
//  AuthScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class AuthScreen: ScreenBase<AuthScreenElement> {
    private lazy var title = staticText(.title)
    private lazy var walletsList = scrollView(.walletsList)

    @discardableResult
    func verifyScreenDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify Auth screen is displayed") { _ in
            waitAndAssertTrue(title, "Auth screen title should be displayed")
            waitAndAssertTrue(walletsList, "Wallets list should be displayed")
            return self
        }
    }

    @discardableResult
    func selectWallet(name: String) -> Self {
        XCTContext.runActivity(named: "Select wallet: \(name)") { _ in
            let walletItem = app.buttons[AuthAccessibilityIdentifiers.walletItem(walletName: name)].firstMatch
            waitAndAssertTrue(walletItem, "Wallet item '\(name)' should exist on Auth screen")
            walletItem.waitAndTap()
            return self
        }
    }

    @discardableResult
    func selectMockCard(name: CardMockAccessibilityIdentifiers) -> MainScreen {
        XCTContext.runActivity(named: "Select mock card from scanner alert: \(name.rawValue)") { _ in
            let walletButton = app.buttons[name.rawValue].firstMatch

            if !walletButton.isHittable {
                app.swipeUp()
            }

            walletButton.waitAndTap()
            return MainScreen(app)
        }
    }
}

enum AuthScreenElement: String, UIElement {
    case title
    case walletsList

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            AuthAccessibilityIdentifiers.title
        case .walletsList:
            AuthAccessibilityIdentifiers.walletsList
        }
    }
}
