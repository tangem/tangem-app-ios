//
//  OnrampKYCVerificationSheetScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class OnrampKYCVerificationSheetScreen: ScreenBase<OnrampKYCVerificationSheetScreenElement> {
    private lazy var icon = image(.icon)
    private lazy var closeButton = button(.closeButton)

    @discardableResult
    func waitForSheetDisplayed(provider: String) -> Self {
        XCTContext.runActivity(named: "Validate KYC verification sheet content") { _ in
            waitAndAssertTrue(icon, "Verification icon should exist")

            let texts = [
                Localization.onrampKycVerificationTitle,
                Localization.onrampKycVerificationSubtitle(provider),
                Localization.onrampKycVerificationWhatsImportant,
                Localization.onrampKycVerificationBulletFree,
                Localization.onrampKycVerificationBulletUnlocks,
                Localization.onrampKycVerificationBulletPrivacy,
            ]
            for text in texts {
                waitAndAssertTrue(app.staticTexts[text].firstMatch, "Text '\(text)' should be displayed on the KYC verification sheet")
            }

            waitAndAssertTrue(verifyButton, "Verify button should exist")
            waitAndAssertTrue(chooseAnotherMethodButton, "Choose another method button should exist")
            waitAndAssertTrue(closeButton, "Close button should exist")
        }
        return self
    }

    func tapVerify() -> OnrampProviderWebPage {
        XCTContext.runActivity(named: "Tap Verify on KYC verification sheet") { _ in
            verifyButton.waitAndTap()
            waitAndAssertTrue(app.webViews.firstMatch, "Provider web view should open after tapping Verify")
            return OnrampProviderWebPage(app)
        }
    }

    private var verifyButton: XCUIElement {
        app.buttons[Localization.onrampKycVerificationVerifyButton].firstMatch
    }

    private var chooseAnotherMethodButton: XCUIElement {
        app.buttons[Localization.onrampKycVerificationChooseAnother].firstMatch
    }
}

enum OnrampKYCVerificationSheetScreenElement: String, UIElement {
    case icon
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .icon:
            return OnrampAccessibilityIdentifiers.kycIcon
        case .closeButton:
            return CommonUIAccessibilityIdentifiers.closeButton
        }
    }
}
