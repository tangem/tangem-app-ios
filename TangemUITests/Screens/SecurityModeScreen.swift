//
//  SecurityModeScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import Foundation

final class SecurityModeScreen: ScreenBase<SecurityModeScreenElement> {
    private static let screenTitle = "Security Mode"

    @discardableResult
    func verifyScreenOpened() -> Self {
        XCTContext.runActivity(named: "Verify Security Mode screen opened") { _ in
            let title = app.navigationBars.staticTexts[Self.screenTitle].firstMatch
            waitAndAssertTrue(title, "Security Mode navigation title should be visible")
            return self
        }
    }
}

enum SecurityModeScreenElement: String, UIElement {
    case unused

    var accessibilityIdentifier: String { rawValue }
}
