//
//  ResetCardScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
import TangemAccessibilityIdentifiers

final class ResetCardScreen: ScreenBase<ResetCardScreenElement> {
    private lazy var accessToCardCheckbox = button(.accessToCard)
    private lazy var accessCodeRecoveryCheckbox = button(.accessCodeRecovery)
    private lazy var resetCardButton = button(.resetCardButton)

    func toggleAccessToCardCheckbox() -> Self {
        XCTContext.runActivity(named: "Select access to card checkbox") { _ in
            accessToCardCheckbox.waitAndTap()
            return self
        }
    }

    func toggleAccessCodeCheckbox() -> Self {
        XCTContext.runActivity(named: "Select access code recovery checkbox") { _ in
            accessCodeRecoveryCheckbox.waitAndTap()
            return self
        }
    }

    @discardableResult
    func validateResetButtonIsDisabled() -> Self {
        XCTContext.runActivity(named: "Validate reset button is disabled") { _ in
            XCTAssertFalse(resetCardButton.isEnabled, "Reset card button should be disabled")
            return self
        }
    }

    @discardableResult
    func validateResetButtonIsEnabled() -> Self {
        XCTContext.runActivity(named: "Validate reset button is enabled") { _ in
            XCTAssertTrue(resetCardButton.isEnabled, "Reset card button should be enabled")
            return self
        }
    }

    func validateScreenElements(by card: CardMockAccessibilityIdentifiers) -> Self {
        XCTContext.runActivity(named: "Validate reset card screen elements") { _ in
            waitAndAssertTrue(accessToCardCheckbox, "Access to card checkbox should exist")
            waitAndAssertTrue(resetCardButton, "Reset card button should exist")
            if card != .walletNoBackup {
                waitAndAssertTrue(accessCodeRecoveryCheckbox, "Access code recovery checkbox should exist")
            }
            return self
        }
    }
}

enum ResetCardScreenElement: String, UIElement {
    case accessToCard
    case accessCodeRecovery
    case resetCardButton

    var accessibilityIdentifier: String {
        switch self {
        case .accessToCard:
            return CardSettingsAccessibilityIdentifiers.accessToCard
        case .accessCodeRecovery:
            return CardSettingsAccessibilityIdentifiers.accessCodeRecovery
        case .resetCardButton:
            return CardSettingsAccessibilityIdentifiers.resetCardButton
        }
    }
}
