//
//  TwinOnboardingScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TwinOnboardingScreen: ScreenBase<TwinOnboardingScreenElement> {
    private lazy var continueButton = button(.continueButton)
    private lazy var titleText = staticText(.titleText)

    @discardableResult
    func tapContinue() -> MainScreen {
        XCTContext.runActivity(named: "Tap Continue button on Twin onboarding screen") { _ in
            continueButton.waitAndTap()
            return MainScreen(app)
        }
    }

    func validateScreen() -> Self {
        XCTContext.runActivity(named: "Validate Twin onboarding screen") { _ in
            XCTAssertTrue(titleText.waitForExistence(timeout: .robustUIUpdate), "Onboarding title should be visible")
            XCTAssertTrue(continueButton.waitForExistence(timeout: .robustUIUpdate), "Continue button should be visible")
            return self
        }
    }
}

enum TwinOnboardingScreenElement: String, UIElement {
    case continueButton
    case titleText

    var accessibilityIdentifier: String {
        switch self {
        case .continueButton:
            "Continue"
        case .titleText:
            "One wallet. Two cards."
        }
    }
}
