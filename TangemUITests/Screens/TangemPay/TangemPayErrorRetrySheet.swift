//
//  TangemPayErrorRetrySheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayErrorRetrySheet: ScreenBase<TangemPayErrorRetrySheetElement> {
    private lazy var icon = app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.popupIcon].firstMatch
    private lazy var closeButton = button(.closeButton)
    private lazy var retryButton = app.buttons[Localization.commonRetry].firstMatch

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for the error sheet") { _ in
            waitAndAssertTrue(retryButton, timeout: .networkRequest, "Retry button should be displayed on the error sheet")
            return self
        }
    }

    @discardableResult
    func verifyContent() -> Self {
        XCTContext.runActivity(named: "Verify the error sheet content") { _ in
            waitAndAssertTrue(icon, "Error icon should be displayed")
            waitAndAssertTrue(app.staticTexts[Localization.commonSomethingWentWrong].firstMatch, "'\(Localization.commonSomethingWentWrong)' should be displayed")
            waitAndAssertTrue(app.staticTexts[Localization.commonTryAgainLater].firstMatch, "'\(Localization.commonTryAgainLater)' should be displayed")
            waitAndAssertTrue(closeButton, "Close button should be displayed")
            XCTAssertEqual(closeButton.label, Localization.commonClose, "Secondary button should read '\(Localization.commonClose)'")
            XCTAssertTrue(retryButton.isEnabled, "Retry button should be enabled")
            return self
        }
    }
}

enum TangemPayErrorRetrySheetElement: String, UIElement {
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .closeButton:
            TangemPayAccessibilityIdentifiers.popupSecondaryButton
        }
    }
}
