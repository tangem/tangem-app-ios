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
    lazy var addressField = button(.addressField)

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Validate MoonPay web view is displayed") { _ in
            let webView = app.webViews.firstMatch

            waitAndAssertTrue(webView, "MoonPay Safari web view should be displayed")
            waitAndAssertTrue(addressField, "Address line should be displayed")

            let urlString = addressField.value as! String
            XCTAssertTrue(
                urlString.contains("sell.moonpay.com"),
                "Address should contain moonpay url, but was: \(urlString)"
            )
        }
        return self
    }
}

enum MoonPageElement: String, UIElement {
    case addressField

    var accessibilityIdentifier: String {
        switch self {
        case .addressField:
            return "URL"
        }
    }
}
