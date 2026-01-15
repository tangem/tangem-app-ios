//
//  SeedImportSuccessScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SeedImportSuccessScreen: ScreenBase<SeedImportSuccessScreenElement> {
    private lazy var continueButton = button(.continueButton)
    private lazy var skipButton = button(.skipButton)
    private lazy var finishButton = button(.finishButton)

    @discardableResult
    func tapContinue() -> Self {
        XCTContext.runActivity(named: "Tap Continue button") { _ in
            continueButton.waitAndTap()
            // Wait for access code screen to appear
            _ = skipButton.waitForExistence(timeout: .networkRequest)
            return self
        }
    }

    @discardableResult
    func skipAccessCode() -> Self {
        XCTContext.runActivity(named: "Skip access code") { _ in
            waitAndAssertTrue(skipButton, "Skip button should exist")
            skipButton.waitAndTap()

            if app.alerts.firstMatch.waitForExistence(timeout: .robustUIUpdate) {
                app.alerts.buttons["Skip anyway"].waitAndTap()
            }

            return self
        }
    }

    @discardableResult
    func tapFinish() -> MainScreen {
        XCTContext.runActivity(named: "Tap Finish button") { _ in
            finishButton.waitAndTap()
            return MainScreen(app)
        }
    }
}

enum SeedImportSuccessScreenElement: String, UIElement {
    case continueButton
    case skipButton
    case finishButton

    var accessibilityIdentifier: String {
        switch self {
        case .continueButton:
            return OnboardingAccessibilityIdentifiers.seedImportSuccessContinueButton
        case .skipButton:
            return OnboardingAccessibilityIdentifiers.accessCodeSkipButton
        case .finishButton:
            return OnboardingAccessibilityIdentifiers.seedImportSuccessFinishButton
        }
    }
}
