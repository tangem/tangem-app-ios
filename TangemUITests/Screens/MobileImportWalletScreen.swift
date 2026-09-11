//
//  MobileImportWalletScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class MobileImportWalletScreen: ScreenBase<MobileImportWalletScreenElement> {
    private lazy var recoveryPhraseButton = button(.recoveryPhraseButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Import Wallet screen") { _ in
            waitAndAssertTrue(recoveryPhraseButton, "Recovery phrase button should be displayed")
            return self
        }
    }

    @discardableResult
    func tapRecoveryPhrase() -> SeedPhraseImportScreen {
        XCTContext.runActivity(named: "Tap Recovery phrase button") { _ in
            waitAndAssertTrue(recoveryPhraseButton, "Recovery phrase button should be displayed")
            recoveryPhraseButton.waitAndTap()
            return SeedPhraseImportScreen(app)
        }
    }
}

enum MobileImportWalletScreenElement: String, UIElement {
    case recoveryPhraseButton
    case iCloudBackupButton

    var accessibilityIdentifier: String {
        switch self {
        case .recoveryPhraseButton:
            return OnboardingAccessibilityIdentifiers.mobileImportWalletRecoveryPhraseButton
        case .iCloudBackupButton:
            return OnboardingAccessibilityIdentifiers.mobileImportWalletICloudBackupButton
        }
    }
}
