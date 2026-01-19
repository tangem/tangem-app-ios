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
    private lazy var manageTokensButton = button(.manageTokens)

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

    func openManageTokens() -> ManageTokensScreen {
        XCTContext.runActivity(named: "Open Manage tokens") { _ in
            manageTokensButton.waitAndTap()
            return ManageTokensScreen(app)
        }
    }

    func goBackToDetails() -> DetailsScreen {
        XCTContext.runActivity(named: "Go back to Details") { _ in
            app.navigationBars.buttons["Details"].waitAndTap()
            return DetailsScreen(app)
        }
    }
}

enum CardSettingsScreenElement: String, UIElement {
    case referralButton
    case deviceSettings
    case manageTokens

    var accessibilityIdentifier: String {
        switch self {
        case .referralButton:
            return CardSettingsAccessibilityIdentifiers.referralProgramButton
        case .deviceSettings:
            return CardSettingsAccessibilityIdentifiers.deviceSettingsButton
        case .manageTokens:
            return CardSettingsAccessibilityIdentifiers.manageTokensButton
        }
    }
}
