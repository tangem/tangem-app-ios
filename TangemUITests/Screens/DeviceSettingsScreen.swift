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
    private lazy var securityModeRow = anyElement(.securityModeRow)

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

    @discardableResult
    func tapSecurityMode() -> SecurityModeScreen {
        XCTContext.runActivity(named: "Tap Security Mode row") { _ in
            scrollToElement(securityModeRow, attempts: .lazy)
            waitAndAssertTrue(securityModeRow, "Security Mode row should exist")
            securityModeRow.waitAndTap()
            return SecurityModeScreen(app)
        }
    }

    @discardableResult
    func verifySecurityModeRowDisabled() -> Self {
        XCTContext.runActivity(named: "Verify Security Mode row is non-interactive") { _ in
            scrollToElement(securityModeRow, attempts: .lazy)
            waitAndAssertTrue(securityModeRow, "Security Mode row should exist")
            let interactiveRow = app.buttons[CardSettingsAccessibilityIdentifiers.securityModeRow]
            XCTAssertFalse(
                interactiveRow.exists,
                "Security Mode row should not be a Button (non-interactive) for this card type"
            )
            return self
        }
    }

    private func anyElement(_ element: DeviceSettingsScreenElement) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: element.accessibilityIdentifier)
            .firstMatch
    }
}

enum DeviceSettingsScreenElement: String, UIElement {
    case resetToFactorySettings
    case securityModeRow

    var accessibilityIdentifier: String {
        switch self {
        case .resetToFactorySettings:
            return CardSettingsAccessibilityIdentifiers.resetToFactorySettingsButton
        case .securityModeRow:
            return CardSettingsAccessibilityIdentifiers.securityModeRow
        }
    }
}
