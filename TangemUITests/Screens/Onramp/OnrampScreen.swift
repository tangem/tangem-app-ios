//
//  OnrampScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class OnrampScreen: ScreenBase<OnrampScreenElement> {
    private lazy var titleLabel = staticText(.title)
    private lazy var closeButton = button(.closeButton)
    private lazy var settingsButton = button(.settingsButton)
    private lazy var allOffersButton = button(.allOffersButton)
    private lazy var currencySelectorButton = button(.currencySelectorButton)
    private lazy var currencySymbolPrefix = staticText(.currencySymbolPrefix)
    private lazy var amountInputField = textField(.amountInputField)

    @discardableResult
    func waitForAmountFieldDisplay(amount: String, currency: String, title: String) throws -> Self {
        try XCTContext.runActivity(named: "Validate OnRamp screen elements") { _ in
            _ = amountInputField.waitForExistence(timeout: .robustUIUpdate)
            let actualValue = try XCTUnwrap(amountInputField.value as? String)
            XCTAssertEqual(actualValue, amount, "TextField placeholder should contain '\(amount)' but was '\(actualValue)'")

            // Validate currency symbol from the separate currency symbol prefix element
            waitAndAssertTrue(currencySymbolPrefix, "Currency symbol prefix should exist")
            let currencySymbol = currencySymbolPrefix.label
            XCTAssertEqual(currencySymbol, currency, "Currency symbol should contain '\(currency)' but was '\(currencySymbol)'")

            waitAndAssertTrue(titleLabel, "Title should exist")
            let actualTitle = titleLabel.label
            XCTAssertEqual(actualTitle, title, "Title should be '\(title)' but was '\(actualTitle)'")

            waitAndAssertTrue(closeButton, "Close button should exist")
        }
        return self
    }

    func tapSettingsButton() -> OnrampSettingsScreen {
        XCTContext.runActivity(named: "Tap Settings button (three dots)") { _ in
            settingsButton.waitAndTap()
            return OnrampSettingsScreen(app)
        }
    }

    @discardableResult
    func waitForCryptoAmountRounding() -> Self {
        XCTContext.runActivity(named: "Validate crypto amount is rounded to 8 decimal places for each provider") { _ in
            // Find all provider amount elements using predicate
            let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "onrampProviderAmount_")
            let providerAmountsQuery = app.staticTexts.matching(predicate)

            // Wait for at least one provider amount to appear
            let firstProviderAmountExists = providerAmountsQuery.element.waitForExistence(timeout: .robustUIUpdate)
            XCTAssertTrue(
                firstProviderAmountExists,
                "At least one provider amount should exist on the screen"
            )

            // Get all matching provider amounts
            let providerAmounts = providerAmountsQuery.allElementsBoundByIndex

            XCTAssertFalse(
                providerAmounts.isEmpty,
                "At least one provider amount should be found"
            )

            // Validate each provider amount
            for (index, providerAmount) in providerAmounts.enumerated() {
                let cryptoAmount = providerAmount.label

                if cryptoAmount.contains(".") {
                    let components = cryptoAmount.components(separatedBy: ".")
                    if components.count == 2 {
                        let decimalPart = components[1]
                        let cleanDecimalPart = decimalPart.replacingOccurrences(
                            of: "[^0-9]",
                            with: "",
                            options: .regularExpression
                        )
                        XCTAssertTrue(
                            cleanDecimalPart.count <= 8,
                            "Provider amount #\(index + 1) should have at most 8 decimal places, but has \(cleanDecimalPart.count): '\(cryptoAmount)'"
                        )
                    }
                }
            }
        }
        return self
    }

    @discardableResult
    func enterAmount(_ amount: String) -> Self {
        XCTContext.runActivity(named: "Enter amount '\(amount)' in amount input field") { _ in
            waitAndAssertTrue(amountInputField, "Amount input field should exist")
            amountInputField.tap()
            amountInputField.typeText(amount)

            // Wait for providers to start loading after amount entry
            // Check if All offers button appears or loading state changes
            let providersExpectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == true"),
                object: allOffersButton
            )

            // Wait up to 5 seconds for providers to become available
            _ = XCTWaiter.wait(for: [providersExpectation], timeout: 5.0)
        }
        return self
    }

    func tapAllOffersButton() -> OnrampPaymentMethodsScreen {
        XCTContext.runActivity(named: "Tap All offers button") { _ in
            allOffersButton.waitAndTap()
            return OnrampPaymentMethodsScreen(app)
        }
    }

    func tapCurrencySelector() -> OnrampCurrencySelectorScreen {
        XCTContext.runActivity(named: "Tap currency selector button (flag + chevron)") { _ in
            XCTAssertTrue(currencySelectorButton.waitForExistence(timeout: .robustUIUpdate), "Currency selector button should exist")
            currencySelectorButton.waitAndTap()
            return OnrampCurrencySelectorScreen(app)
        }
    }

    @discardableResult
    func validateCurrencyChanged(expectedCurrency: String) -> Self {
        XCTContext.runActivity(named: "Validate currency changed to '\(expectedCurrency)'") { _ in
            // Wait for currency symbol prefix to appear and reflect expected currency
            XCTAssertTrue(
                currencySymbolPrefix.waitForExistence(timeout: .robustUIUpdate),
                "Currency symbol prefix should exist"
            )

            let actualLabel = currencySymbolPrefix.label
            XCTAssertTrue(
                actualLabel.contains(expectedCurrency),
                "Currency symbol should contain '\(expectedCurrency)' but was '\(actualLabel)'"
            )
        }
        return self
    }

    // MARK: - Error View Methods

    @discardableResult
    func waitForErrorView() -> Self {
        XCTContext.runActivity(named: "Validate error notification view exists") { _ in
            let refreshButton = app.buttons[CommonUIAccessibilityIdentifiers.notificationButton]
            waitAndAssertTrue(refreshButton, "Error notification view does not exist - refresh button not found after waiting")
        }
        return self
    }

    @discardableResult
    func validateErrorContent(title: String? = nil, message: String? = nil) -> Self {
        XCTContext.runActivity(named: "Validate error notification content") { _ in
            if let title = title {
                let titleLabel = app.staticTexts[CommonUIAccessibilityIdentifiers.notificationTitle]
                XCTAssertTrue(titleLabel.waitForExistence(timeout: .robustUIUpdate), "Error title should exist")
                XCTAssertEqual(titleLabel.label, title, "Error title should be '\(title)' but was '\(titleLabel.label)'")
            }

            if let message = message {
                let messageLabel = app.staticTexts[CommonUIAccessibilityIdentifiers.notificationMessage]
                XCTAssertTrue(messageLabel.waitForExistence(timeout: .robustUIUpdate), "Error message should exist")
                XCTAssertEqual(messageLabel.label, message, "Error message should be '\(message)' but was '\(messageLabel.label)'")
            }
        }
        return self
    }

    /// Wait for providers to load after amount changes
    @discardableResult
    func waitForProvidersToLoad() -> Self {
        XCTContext.runActivity(named: "Wait for providers to load") { _ in
            waitAndAssertTrue(
                allOffersButton,
                "All offers button should appear after providers load"
            )

            XCTAssertTrue(
                allOffersButton.waitForState(state: .hittable, for: .robustUIUpdate),
                "All offers button should be ready for interaction"
            )
        }
        return self
    }

    @discardableResult
    func waitForTitle(_ expectedTitle: String) -> Self {
        XCTContext.runActivity(named: "Validate Onramp screen title") { _ in
            waitAndAssertTrue(titleLabel, "Title should exist on Onramp screen")
            let actualTitle = titleLabel.label
            XCTAssertEqual(actualTitle, expectedTitle, "Title should be '\(expectedTitle)' but was '\(actualTitle)'")
        }
        return self
    }
}

enum OnrampScreenElement: String, UIElement {
    case title
    case closeButton
    case settingsButton
    case allOffersButton
    case currencySelectorButton
    case currencySymbolPrefix
    case amountInputField

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return SendAccessibilityIdentifiers.sendViewTitle
        case .closeButton:
            return "Close"
        case .settingsButton:
            return OnrampAccessibilityIdentifiers.settingsButton
        case .allOffersButton:
            return OnrampAccessibilityIdentifiers.allOffersButton
        case .currencySelectorButton:
            return OnrampAccessibilityIdentifiers.currencySelectorButton
        case .currencySymbolPrefix:
            return OnrampAccessibilityIdentifiers.currencySymbolPrefix
        case .amountInputField:
            return OnrampAccessibilityIdentifiers.amountInputField
        }
    }
}
