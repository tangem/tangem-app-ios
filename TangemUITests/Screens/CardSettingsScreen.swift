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
}

enum CardSettingsScreenElement: String, UIElement {
    case referralButton
    case deviceSettings

    var accessibilityIdentifier: String {
        switch self {
        case .referralButton:
            return CardSettingsAccessibilityIdentifiers.referralProgramButton
        case .deviceSettings:
            return CardSettingsAccessibilityIdentifiers.deviceSettingsButton
        }
    }
}
