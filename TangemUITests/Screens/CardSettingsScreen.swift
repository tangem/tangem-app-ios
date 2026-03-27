//
//  CardSettingsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
import TangemAccessibilityIdentifiers

final class CardSettingsScreen: ScreenBase<CardSettingsScreenElement> {
    private lazy var referralButton = button(.referralButton)
    private lazy var deviceSettingsButton = button(.deviceSettings)
    private lazy var addAccountButton = button(.addAccount)

    func openReferralProgram() -> ReferralScreen {
        XCTContext.runActivity(named: "Open referral program screen") { _ in
            referralButton.waitAndTap()
            return ReferralScreen(app)
        }
    }

    func openDeviceSettings() -> ScanCardSettingsScreen {
        XCTContext.runActivity(named: "Open device settings") { _ in
            deviceSettingsButton.waitAndTap()
            return ScanCardSettingsScreen(app)
        }
    }

    func selectAccount(_ accName: String) -> AccountSettingsScreen {
        XCTContext.runActivity(named: "Select account: \(accName)") { _ in
            let accountButton = app.buttons[AccountsAccessibilityIdentifiers.walletSettingsAccountRow(accountName: accName)]
            accountButton.waitAndTap()
            return AccountSettingsScreen(app)
        }
    }

    func goBackToDetails() -> DetailsScreen {
        XCTContext.runActivity(named: "Go back to Details") { _ in
            app.navigationBars.buttons["Details"].waitAndTap()
            return DetailsScreen(app)
        }
    }

    // MARK: - Account Management

    func tapAddAccount() -> AccountFormScreen {
        XCTContext.runActivity(named: "Tap 'Add account' button") { _ in
            scrollToElement(addAccountButton)
            addAccountButton.waitAndTap()
            return AccountFormScreen(app)
        }
    }

    @discardableResult
    func verifyAddAccountButtonEnabled() -> Self {
        XCTContext.runActivity(named: "Verify 'Add account' button is enabled") { _ in
            scrollToElement(addAccountButton)
            waitAndAssertTrue(addAccountButton, "Add account button should exist")
            XCTAssertTrue(addAccountButton.isEnabled, "Add account button should be enabled")
            return self
        }
    }
}

enum CardSettingsScreenElement: String, UIElement {
    case referralButton
    case deviceSettings
    case addAccount

    var accessibilityIdentifier: String {
        switch self {
        case .referralButton:
            return CardSettingsAccessibilityIdentifiers.referralProgramButton
        case .deviceSettings:
            return CardSettingsAccessibilityIdentifiers.deviceSettingsButton
        case .addAccount:
            return AccountsAccessibilityIdentifiers.walletSettingsAddAccountButton
        }
    }
}
