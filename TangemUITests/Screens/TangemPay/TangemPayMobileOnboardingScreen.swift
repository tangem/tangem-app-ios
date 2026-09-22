//
//  TangemPayMobileOnboardingScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayMobileOnboardingScreen: ScreenBase<TangemPayMobileOnboardingScreenElement> {
    private lazy var title = staticText(.mobileOnboardingTitle)
    private lazy var getCardButton = button(.mobileOnboardingGetCardButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Tangem Pay mobile onboarding screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "Tangem Pay mobile onboarding title should be displayed")
            waitAndAssertTrue(getCardButton, "Get card button should be displayed on the mobile onboarding screen")
            return self
        }
    }

    @discardableResult
    func tapGetCard() -> MainScreen {
        XCTContext.runActivity(named: "Tap Get card button") { _ in
            getCardButton.waitAndTap()
            return MainScreen(app)
        }
    }
}

enum TangemPayMobileOnboardingScreenElement: String, UIElement {
    case mobileOnboardingTitle
    case mobileOnboardingGetCardButton

    var accessibilityIdentifier: String {
        switch self {
        case .mobileOnboardingTitle:
            return TangemPayAccessibilityIdentifiers.mobileOnboardingTitle
        case .mobileOnboardingGetCardButton:
            return TangemPayAccessibilityIdentifiers.mobileOnboardingGetCardButton
        }
    }
}
