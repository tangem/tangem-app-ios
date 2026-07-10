//
//  YieldModulePromoScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class YieldModulePromoScreen: ScreenBase<YieldModulePromoScreenElement> {
    private lazy var continueButton = button(.continueButton)

    @discardableResult
    func tapContinue() -> YieldModuleStartEarningScreen {
        XCTContext.runActivity(named: "Tap 'Continue' button on yield promo screen") { _ in
            continueButton.waitAndTap()
            return YieldModuleStartEarningScreen(app)
        }
    }
}

enum YieldModulePromoScreenElement: String, UIElement {
    case continueButton

    var accessibilityIdentifier: String {
        switch self {
        case .continueButton:
            return YieldModuleAccessibilityIdentifiers.promoContinueButton
        }
    }
}
