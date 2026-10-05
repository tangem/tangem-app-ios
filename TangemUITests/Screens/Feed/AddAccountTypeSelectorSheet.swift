//
//  AddAccountTypeSelectorSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class AddAccountTypeSelectorSheet: Screen {
    let app: XCUIApplication

    private lazy var cryptoAccountButton = app.buttons[AccountsAccessibilityIdentifiers.addAccountTypeSelectorCryptoAccountButton].firstMatch
    private lazy var jointAccountButton = app.buttons[AccountsAccessibilityIdentifiers.addAccountTypeSelectorJointAccountButton].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func verifyCryptoAccountOptionClickable() -> Self {
        XCTContext.runActivity(named: "Verify 'Crypto account' option is displayed and clickable") { _ in
            assertClickable(cryptoAccountButton, name: "Crypto account")
            return self
        }
    }

    @discardableResult
    func verifyJointAccountOptionClickable() -> Self {
        XCTContext.runActivity(named: "Verify 'Joint account' option is displayed and clickable") { _ in
            assertClickable(jointAccountButton, name: "Joint account")
            return self
        }
    }

    @discardableResult
    func tapCryptoAccount() -> AccountFormScreen {
        XCTContext.runActivity(named: "Tap 'Crypto account' option") { _ in
            cryptoAccountButton.waitAndTap()
            return AccountFormScreen(app)
        }
    }

    @discardableResult
    func tapCryptoAccountExpectingAccountLimit() -> AccountLimitReachedAlert {
        XCTContext.runActivity(named: "Tap 'Crypto account' option expecting the account limit popup") { _ in
            cryptoAccountButton.waitAndTap()
            return AccountLimitReachedAlert(app)
        }
    }

    @discardableResult
    func tapJointAccountExpectingAccountLimit() -> AccountLimitReachedAlert {
        XCTContext.runActivity(named: "Tap 'Joint account' option expecting the account limit popup") { _ in
            jointAccountButton.waitAndTap()
            return AccountLimitReachedAlert(app)
        }
    }

    private func assertClickable(_ element: XCUIElement, name: String) {
        waitAndAssertTrue(element, "'\(name)' option should be displayed")
        element.waitForState(state: .hittable)
        element.waitForState(state: .enabled)
    }
}
