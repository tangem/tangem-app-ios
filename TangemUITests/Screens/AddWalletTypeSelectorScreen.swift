//
//  AddWalletTypeSelectorScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class AddWalletTypeSelectorScreen: ScreenBase<AddWalletTypeSelectorScreenElement> {
    private lazy var hardwareWalletButton = button(.hardwareWalletButton)
    private lazy var mobileWalletButton = button(.mobileWalletButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Add Wallet type selector") { _ in
            waitAndAssertTrue(hardwareWalletButton, "Hardware wallet row should be displayed")
            return self
        }
    }

    @discardableResult
    func tapHardwareWallet() -> DetailsScreen {
        XCTContext.runActivity(named: "Tap Hardware wallet") { _ in
            waitAndAssertTrue(hardwareWalletButton, "Hardware wallet row should be displayed")
            hardwareWalletButton.waitAndTap()
            return DetailsScreen(app)
        }
    }
}

enum AddWalletTypeSelectorScreenElement: String, UIElement {
    case hardwareWalletButton
    case mobileWalletButton

    var accessibilityIdentifier: String {
        switch self {
        case .hardwareWalletButton:
            return DetailsAccessibilityIdentifiers.addWalletTypeHardwareButton
        case .mobileWalletButton:
            return DetailsAccessibilityIdentifiers.addWalletTypeMobileButton
        }
    }
}
