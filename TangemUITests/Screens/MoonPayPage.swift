//
//  MoonPayPage.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation

final class MoonPayPage: ScreenBase<MoonPageElement> {
    lazy var continueButton = button(.continueButton)

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Validate MoonPay web view is displayed") { _ in
            let webView = app.webViews.firstMatch

            waitAndAssertTrue(webView, "MoonPay Safari web view should be displayed")
            waitAndAssertTrue(continueButton, "Continue button should be displayed")
        }
        return self
    }
}

enum MoonPageElement: String, UIElement {
    case continueButton

    var accessibilityIdentifier: String {
        switch self {
        case .continueButton:
            return "Continue"
        }
    }
}
