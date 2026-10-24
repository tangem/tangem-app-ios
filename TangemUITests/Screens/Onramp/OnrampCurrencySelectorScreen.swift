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
    private lazy var retryButton = button(.retryButton)

    @discardableResult
    func validate() -> Self {
        XCTContext.runActivity(named: "Validate OnRamp Currency Selector screen elements") { _ in
            XCTAssertTrue(popularSection.waitForExistence(timeout: .robustUIUpdate), "Popular section should exist")
            XCTAssertTrue(otherSection.waitForExistence(timeout: .robustUIUpdate), "Other section should exist")
        }
        return self
    }

    @discardableResult
    func waitForLoadError() -> Self {
        XCTContext.runActivity(named: "Validate currencies load error is displayed") { _ in
            waitAndAssertTrue(app.staticTexts[Localization.marketsLoadingErrorTitle].firstMatch, "Load error title should exist")
            waitAndAssertTrue(retryButton, "Try again button should exist")
            XCTAssertEqual(retryButton.label, Localization.tryToLoadDataAgainButtonTitle, "Retry button title mismatch")
        }
        return self
    }

    @discardableResult
    func tapTryAgain() -> Self {
        XCTContext.runActivity(named: "Tap Try again on currencies load error") { _ in
            retryButton.waitAndTap()
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
    case retryButton

    var accessibilityIdentifier: String {
        switch self {
        case .popularSection:
            return OnrampAccessibilityIdentifiers.currencySelectorPopularSection
        case .otherSection:
            return OnrampAccessibilityIdentifiers.currencySelectorOtherSection
        case .retryButton:
            return CommonUIAccessibilityIdentifiers.retryButton
        }
    }
}
