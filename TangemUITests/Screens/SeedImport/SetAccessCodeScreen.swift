//
//  SetAccessCodeScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SetAccessCodeScreen: ScreenBase<SetAccessCodeScreenElement> {
    private lazy var title = staticText(.title)
    private lazy var input = textField(.input)
    private lazy var skipButton = button(.skipButton)

    @discardableResult
    func skipAccessCode(timeout: TimeInterval = .networkRequest) -> SeedImportSuccessScreen {
        XCTContext.runActivity(named: "Skip access code") { _ in
            skipButton.tap()

            // Confirm skipping if alert is shown.
            let alert = app.alerts.firstMatch
            if alert.waitForExistence(timeout: .robustUIUpdate) {
                alert.buttons["Skip anyway"].tap()
            }

            return SeedImportSuccessScreen(app)
        }
    }
}

enum SetAccessCodeScreenElement: String, UIElement {
    case title
    case input
    case skipButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return OnboardingAccessibilityIdentifiers.title
        case .input:
            return OnboardingAccessibilityIdentifiers.accessCodeInputField
        case .skipButton:
            return OnboardingAccessibilityIdentifiers.accessCodeSkipButton
        }
    }
}
