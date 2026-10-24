//
//  WelcomeImportSheetScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class WelcomeImportSheetScreen: ScreenBase<WelcomeImportSheetScreenElement> {
    private lazy var recoveryPhraseButton = button(.recoveryPhraseButton)

    @discardableResult
    func tapRecoveryPhrase() -> SeedPhraseImportScreen {
        XCTContext.runActivity(named: "Tap Recovery phrase button") { _ in
            waitAndAssertTrue(recoveryPhraseButton, "Recovery phrase button should be displayed")
            recoveryPhraseButton.waitAndTap()
            return SeedPhraseImportScreen(app)
        }
    }
}

enum WelcomeImportSheetScreenElement: String, UIElement {
    case recoveryPhraseButton
    case iCloudBackupButton

    var accessibilityIdentifier: String {
        switch self {
        case .recoveryPhraseButton:
            OnboardingAccessibilityIdentifiers.welcomeImportSheetRecoveryPhraseButton
        case .iCloudBackupButton:
            OnboardingAccessibilityIdentifiers.welcomeImportSheetICloudBackupButton
        }
    }
}
