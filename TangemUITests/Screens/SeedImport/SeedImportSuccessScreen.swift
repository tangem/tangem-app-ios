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
    private lazy var finishButton = button(.finishButton)

    @discardableResult
    func tapContinue() -> SetAccessCodeScreen {
        XCTContext.runActivity(named: "Tap Continue button") { _ in
            continueButton.tap()
            return SetAccessCodeScreen(app)
        }
    }

    @discardableResult
    func tapFinish() -> MainScreen {
        XCTContext.runActivity(named: "Tap Finish button") { _ in
            finishButton.tap()
            return MainScreen(app)
        }
    }
}

enum SeedImportSuccessScreenElement: String, UIElement {
    case continueButton
    case finishButton

    var accessibilityIdentifier: String {
        switch self {
        case .continueButton:
            return OnboardingAccessibilityIdentifiers.seedImportSuccessContinueButton
        case .finishButton:
            return OnboardingAccessibilityIdentifiers.seedImportSuccessFinishButton
        }
    }
}
