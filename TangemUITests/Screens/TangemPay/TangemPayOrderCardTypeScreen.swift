//
//  TangemPayOrderCardTypeScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayOrderCardTypeScreen: ScreenBase<TangemPayOrderCardTypeScreenElement> {
    private lazy var selectButton = button(.selectButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Order card type screen") { _ in
            waitAndAssertTrue(selectButton, timeout: .networkRequest, "Select button should be displayed on Order card type screen")
            return self
        }
    }

    /// Virtual is the preselected type, so selecting it only takes confirming the screen.
    @discardableResult
    func selectVirtual() -> TangemPayIssueAdditionalCardSheet {
        XCTContext.runActivity(named: "Select the virtual card type") { _ in
            selectButton.waitAndTap()
            return TangemPayIssueAdditionalCardSheet(app)
        }
    }
}

enum TangemPayOrderCardTypeScreenElement: String, UIElement {
    case selectButton

    var accessibilityIdentifier: String {
        switch self {
        case .selectButton:
            TangemPayAccessibilityIdentifiers.orderCardTypeSelectButton
        }
    }
}
