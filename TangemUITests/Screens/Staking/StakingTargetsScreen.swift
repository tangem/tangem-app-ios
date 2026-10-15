//
//  StakingTargetsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class StakingTargetsScreen: ScreenBase<StakingTargetsScreenElement> {
    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Wait for validator (staking target) list to display") { _ in
            let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "stakingTargets_button_")
            let firstTarget = app.buttons.matching(predicate).firstMatch
            waitAndAssertTrue(firstTarget, "At least one staking target should be displayed")
        }
        return self
    }

    @discardableResult
    func selectTarget(name: String) -> Self {
        XCTContext.runActivity(named: "Select staking target '\(name)'") { _ in
            let target = app.buttons[StakingAccessibilityIdentifiers.stakingTargetsButton(name: name)].firstMatch
            waitAndAssertTrue(target, "Staking target '\(name)' should exist")
            target.waitAndTap()
        }
        return self
    }

    @discardableResult
    func tapContinue() -> SendSummaryScreen {
        XCTContext.runActivity(named: "Tap Continue to return to the summary with the new target") { _ in
            let continueButton = app.buttons[SendAccessibilityIdentifiers.sendViewNextButton].firstMatch
            waitAndAssertTrue(continueButton, "Continue button should exist")
            continueButton.waitAndTap()
        }
        return SendSummaryScreen(app)
    }
}

enum StakingTargetsScreenElement: UIElement {
    var accessibilityIdentifier: String {
        switch self {}
    }
}
