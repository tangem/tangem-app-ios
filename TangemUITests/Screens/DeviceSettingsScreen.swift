//
//  DeviceSettingsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
import TangemAccessibilityIdentifiers

final class DeviceSettingsScreen: ScreenBase<DeviceSettingsScreenElement> {
    private lazy var resetToFactorySettingsButton = button(.resetToFactorySettings)

    @discardableResult
    func openResetToFactorySettings() -> ResetCardScreen {
        XCTContext.runActivity(named: "Open reset to factory settings screen") { _ in
            resetToFactorySettingsButton.waitAndTap()
            return ResetCardScreen(app)
        }
    }

    func validateScreenElements() -> Self {
        XCTContext.runActivity(named: "Validate device settings screen elements") { _ in
            XCTAssertTrue(resetToFactorySettingsButton.waitForExistence(timeout: .robustUIUpdate), "Reset to factory settings button should exist")
            return self
        }
    }
}

enum DeviceSettingsScreenElement: String, UIElement {
    case resetToFactorySettings

    var accessibilityIdentifier: String {
        switch self {
        case .resetToFactorySettings:
            return CardSettingsAccessibilityIdentifiers.resetToFactorySettingsButton
        }
    }
}
