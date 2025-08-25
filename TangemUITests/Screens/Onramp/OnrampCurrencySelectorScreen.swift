//
//  OnrampCurrencySelectorScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class OnrampCurrencySelectorScreen: ScreenBase<OnrampCurrencySelectorScreenElement> {
    private lazy var popularSection = staticText(.popularSection)
    private lazy var otherSection = staticText(.otherSection)

    @discardableResult
    func validate() -> Self {
        XCTContext.runActivity(named: "Validate OnRamp Currency Selector screen elements") { _ in
            XCTAssertTrue(popularSection.waitForExistence(timeout: .robustUIUpdate), "Popular section should exist")
            XCTAssertTrue(otherSection.waitForExistence(timeout: .robustUIUpdate), "Other section should exist")
        }
        return self
    }

    func selectCurrency(_ currencyCode: String) -> OnrampScreen {
        XCTContext.runActivity(named: "Select currency '\(currencyCode)'") { _ in
            let currencyButton = app.buttons[OnrampAccessibilityIdentifiers.currencyItem(code: currencyCode)]
            XCTAssertTrue(currencyButton.waitForExistence(timeout: .robustUIUpdate), "Currency '\(currencyCode)' should exist")
            currencyButton.tap()
            return OnrampScreen(app)
        }
    }

    @discardableResult
    func validateCurrencyExists(_ currencyCode: String) -> Self {
        XCTContext.runActivity(named: "Validate currency '\(currencyCode)' exists") { _ in
            let currencyButton = app.buttons[OnrampAccessibilityIdentifiers.currencyItem(code: currencyCode)]
            XCTAssertTrue(currencyButton.waitForExistence(timeout: .robustUIUpdate), "Currency '\(currencyCode)' should exist")
        }
        return self
    }
}

enum OnrampCurrencySelectorScreenElement: String, UIElement {
    case popularSection
    case otherSection

    var accessibilityIdentifier: String {
        switch self {
        case .popularSection:
            return OnrampAccessibilityIdentifiers.currencySelectorPopularSection
        case .otherSection:
            return OnrampAccessibilityIdentifiers.currencySelectorOtherSection
        }
    }
}
