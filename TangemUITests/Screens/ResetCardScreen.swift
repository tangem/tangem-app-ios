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
    private lazy var firstCheckbox = button(.firstCheckbox)
    private lazy var secondCheckbox = button(.secondCheckbox)
    private lazy var resetCardButton = button(.resetCardButton)

    func selectFirstCheckbox() -> Self {
        XCTContext.runActivity(named: "Select first checkbox") { _ in
            firstCheckbox.waitAndTap()
            return self
        }
    }

    func selectSecondCheckbox() -> Self {
        XCTContext.runActivity(named: "Select second checkbox") { _ in
            secondCheckbox.waitAndTap()
            return self
        }
    }

    func unselectFirstCheckbox() -> Self {
        XCTContext.runActivity(named: "Unselect first checkbox") { _ in
            firstCheckbox.waitAndTap()
            return self
        }
    }

    func unselectSecondCheckbox() -> Self {
        XCTContext.runActivity(named: "Unselect second checkbox") { _ in
            secondCheckbox.waitAndTap()
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

    func validateScreenElements() -> Self {
        XCTContext.runActivity(named: "Validate reset card screen elements") { _ in
            XCTAssertTrue(firstCheckbox.waitForExistence(timeout: .robustUIUpdate), "First checkbox should exist")
            XCTAssertTrue(secondCheckbox.waitForExistence(timeout: .robustUIUpdate), "Second checkbox should exist")
            XCTAssertTrue(resetCardButton.waitForExistence(timeout: .robustUIUpdate), "Reset card button should exist")
            return self
        }
    }
}

enum ResetCardScreenElement: String, UIElement {
    case firstCheckbox
    case secondCheckbox
    case resetCardButton

    var accessibilityIdentifier: String {
        switch self {
        case .firstCheckbox:
            return CardSettingsAccessibilityIdentifiers.firstCheckbox
        case .secondCheckbox:
            return CardSettingsAccessibilityIdentifiers.secondCheckbox
        case .resetCardButton:
            return CardSettingsAccessibilityIdentifiers.resetCardButton
        }
    }
}
