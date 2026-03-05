//
//  SeedPhraseImportScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SeedPhraseImportScreen: ScreenBase<SeedPhraseImportScreenElement> {
    private lazy var seedPhraseTextField = textView(.seedPhraseTextField)
    private lazy var passphraseTextField = textField(.passphraseTextField)
    private lazy var importButton = button(.importButton)

    @discardableResult
    func enterSeedPhrase(_ seedPhrase: String) -> Self {
        XCTContext.runActivity(named: "Enter seed phrase") { _ in
            waitAndAssertTrue(seedPhraseTextField, "Seed phrase text field should exist")
            seedPhraseTextField.tap()
            seedPhraseTextField.typeText(seedPhrase)
            return self
        }
    }

    @discardableResult
    func enterPassphrase(_ passphrase: String) -> Self {
        XCTContext.runActivity(named: "Enter passphrase") { _ in
            if passphraseTextField.waitForExistence(timeout: .robustUIUpdate) {
                passphraseTextField.tap()

                if let currentText = passphraseTextField.value as? String, !currentText.isEmpty {
                    deleteText(element: passphraseTextField)
                }
                passphraseTextField.typeText(passphrase)
            }
            return self
        }
    }

    @discardableResult
    func tapImportButton() -> SeedImportSuccessScreen {
        XCTContext.runActivity(named: "Tap Import button") { _ in
            importButton.waitAndTap()
            return SeedImportSuccessScreen(app)
        }
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Seed Phrase Import screen") { _ in
            waitAndAssertTrue(seedPhraseTextField, "Seed phrase text field should be displayed")
            return self
        }
    }
}

enum SeedPhraseImportScreenElement: String, UIElement {
    case seedPhraseTextField
    case passphraseTextField
    case importButton

    var accessibilityIdentifier: String {
        switch self {
        case .seedPhraseTextField:
            return OnboardingAccessibilityIdentifiers.seedPhraseImportTextField
        case .passphraseTextField:
            return OnboardingAccessibilityIdentifiers.seedPhraseImportPassphraseField
        case .importButton:
            return OnboardingAccessibilityIdentifiers.seedPhraseImportButton
        }
    }
}
