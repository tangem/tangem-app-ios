//
//  YieldModuleTransactionScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class YieldModuleTransactionScreen: ScreenBase<YieldModuleTransactionScreenElement> {
    private lazy var confirmButton = app
        .descendants(matching: .any)[YieldModuleAccessibilityIdentifiers.confirmButton]
        .firstMatch

    @discardableResult
    func holdToConfirm() -> TokenScreen {
        XCTContext.runActivity(named: "Hold 'Confirm' button to confirm transaction") { _ in
            waitAndAssertTrue(confirmButton, "'Confirm' button should be displayed")
            confirmButton.press(forDuration: YieldModuleHoldToConfirm.duration)
            XCTAssertTrue(
                confirmButton.waitForNonExistence(timeout: .robustUIUpdate),
                "'Confirm' button should be dismissed after confirmation"
            )
            return TokenScreen(app)
        }
    }
}

enum YieldModuleTransactionScreenElement: String, UIElement {
    case confirmButton

    var accessibilityIdentifier: String {
        switch self {
        case .confirmButton:
            return YieldModuleAccessibilityIdentifiers.confirmButton
        }
    }
}
