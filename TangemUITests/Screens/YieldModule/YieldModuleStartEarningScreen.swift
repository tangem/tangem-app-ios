//
//  YieldModuleStartEarningScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class YieldModuleStartEarningScreen: ScreenBase<YieldModuleStartEarningScreenElement> {
    private lazy var startEarningButton = app
        .descendants(matching: .any)[YieldModuleAccessibilityIdentifiers.startEarningButton]
        .firstMatch

    @discardableResult
    func holdToStartEarning() -> TokenScreen {
        XCTContext.runActivity(named: "Hold 'Start earning' button to confirm activation") { _ in
            waitAndAssertTrue(startEarningButton, "'Start earning' button should be displayed")
            startEarningButton.press(forDuration: YieldModuleHoldToConfirm.duration)
            XCTAssertTrue(
                startEarningButton.waitForNonExistence(timeout: .robustUIUpdate),
                "'Start earning' button should be dismissed after confirmation"
            )
            return TokenScreen(app)
        }
    }
}

enum YieldModuleStartEarningScreenElement: String, UIElement {
    case startEarningButton

    var accessibilityIdentifier: String {
        switch self {
        case .startEarningButton:
            return YieldModuleAccessibilityIdentifiers.startEarningButton
        }
    }
}
