//
//  MobileCreateWalletScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class MobileCreateWalletScreen: ScreenBase<MobileCreateWalletScreenElement> {
    private lazy var importButton = button(.importButton)
    private lazy var createButton = button(.createButton)

    @discardableResult
    func tapImportButton() -> SeedPhraseImportScreen {
        XCTContext.runActivity(named: "Tap Import button") { _ in
            waitAndAssertTrue(importButton, "Import button should be displayed")
            importButton.waitAndTap()

            // Welcome V2 may insert a recovery-phrase-vs-iCloud choice sheet before the seed phrase screen; tap through it if present.
            let recoveryPhrasePredicate = NSPredicate(
                format: "identifier == %@ OR label == %@",
                OnboardingAccessibilityIdentifiers.welcomeImportSheetRecoveryPhraseButton,
                "Import recovery phrase"
            )
            let recoveryPhraseButton = app.buttons.matching(recoveryPhrasePredicate).firstMatch
            if recoveryPhraseButton.waitForExistence(timeout: .quick) {
                recoveryPhraseButton.waitAndTap()
            }

            return SeedPhraseImportScreen(app)
        }
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Mobile Create Wallet screen") { _ in
            waitAndAssertTrue(importButton, "Import button should be displayed")
            return self
        }
    }
}

enum MobileCreateWalletScreenElement: String, UIElement {
    case importButton
    case createButton

    var accessibilityIdentifier: String {
        switch self {
        case .importButton:
            return OnboardingAccessibilityIdentifiers.mobileCreateWalletImportButton
        case .createButton:
            return OnboardingAccessibilityIdentifiers.mobileCreateWalletCreateButton
        }
    }
}
