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
    private lazy var providerToSLink = staticText(.providerToSLink)
    private lazy var cryptoAmountLabel = staticText(.cryptoAmountLabel)
    private lazy var payWithBlock = button(.payWithBlock)
    private lazy var currencySelectorButton = button(.currencySelectorButton)

    private var amountInputField: XCUIElement {
        app.textFields
            .matching(identifier: OnrampAccessibilityIdentifiers.amountInputField)
            .element(boundBy: 0)
    }

    private var amountDisplayField: XCUIElement {
        let textFields = app.textFields.matching(identifier: OnrampAccessibilityIdentifiers.amountInputField)
        if textFields.count > 1 {
            return textFields.element(boundBy: 1)
        }

        // Fallback to StaticText if only one TextField exists
        return app.staticTexts
            .matching(identifier: OnrampAccessibilityIdentifiers.amountInputField)
            .firstMatch
    }

    @discardableResult
    func validate(amount: String, currency: String, title: String) -> Self {
        XCTContext.runActivity(named: "Validate OnRamp screen elements") { _ in
            let actualValue = amountDisplayField.getValue()
            XCTAssertTrue(actualValue.contains(amount), "TextField value should contain '\(amount)' but was '\(actualValue)'")
            XCTAssertTrue(actualValue.contains(currency), "TextField value should contain '\(currency)' but was '\(actualValue)'")

            XCTAssertTrue(titleLabel.waitForExistence(timeout: .longUIUpdate), "Title should exist")
            let actualTitle = titleLabel.label
            XCTAssertEqual(actualTitle, title, "Title should be '\(title)' but was '\(actualTitle)'")

            XCTAssertTrue(closeButton.waitForExistence(timeout: .longUIUpdate), "Close button should exist")
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
    func validateProviderToSLinkExists() -> Self {
        XCTContext.runActivity(named: "Validate Provider ToS link exists") { _ in
            XCTAssertTrue(providerToSLink.waitForExistence(timeout: .longUIUpdate), "Provider ToS link should exist")
        }
        return self
    }

    @discardableResult
    func validateCryptoAmountRounding() -> Self {
        XCTContext.runActivity(named: "Validate crypto amount is rounded to 8 decimal places") { _ in
            XCTAssertTrue(cryptoAmountLabel.waitForExistence(timeout: .longUIUpdate), "Crypto amount label should exist")
            let cryptoAmount = cryptoAmountLabel.label

            if cryptoAmount.contains(".") {
                let components = cryptoAmount.components(separatedBy: ".")
                if components.count == 2 {
                    let decimalPart = components[1]
                    let cleanDecimalPart = decimalPart.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                    XCTAssertTrue(cleanDecimalPart.count <= 8, "Crypto amount should have at most 8 decimal places, but has \(cleanDecimalPart.count): '\(cryptoAmount)'")
                }
            }
        }
        return self
    }

    @discardableResult
    func enterAmount(_ amount: String) -> Self {
        XCTContext.runActivity(named: "Enter amount '\(amount)' in amount input field") { _ in
            XCTAssertTrue(amountInputField.waitForExistence(timeout: .longUIUpdate), "Amount input field should exist")
            amountInputField.tap()
            amountInputField.typeText(amount)
            app.hideKeyboard()

            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == true"),
                object: amountDisplayField
            )
            _ = XCTWaiter.wait(for: [expectation], timeout: 3.0)
        }
        return self
    }

    @discardableResult
    func validateCryptoAmount() -> Self {
        XCTContext.runActivity(named: "Validate crypto amount is updated and properly formatted") { _ in
            XCTAssertTrue(cryptoAmountLabel.waitForExistence(timeout: .quickNetworkRequest), "Crypto amount label should exist")
            let cryptoAmount = cryptoAmountLabel.label

            XCTAssertFalse(cryptoAmount.isEmpty, "Crypto amount should not be empty")
            XCTAssertFalse(cryptoAmount.contains("0.00000000"), "Crypto amount should be recalculated and not be zero")

            let hasDigits = cryptoAmount.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
            XCTAssertTrue(hasDigits, "Crypto amount should contain digits: '\(cryptoAmount)'")

            if cryptoAmount.contains(".") {
                let components = cryptoAmount.components(separatedBy: ".")
                if components.count == 2 {
                    let decimalPart = components[1]
                    let cleanDecimalPart = decimalPart.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                    XCTAssertTrue(cleanDecimalPart.count <= 8, "Crypto amount should have at most 8 decimal places, but has \(cleanDecimalPart.count): '\(cryptoAmount)'")
                } else {
                    XCTFail("Crypto amount format is unexpected: '\(cryptoAmount)'")
                }
            }
        }
        return self
    }

    func tapPayWithBlock() -> OnrampProvidersScreen {
        XCTContext.runActivity(named: "Tap Pay with block") { _ in
            _ = payWithBlock.waitForExistence(timeout: .longUIUpdate)
            XCTAssertTrue(payWithBlock.exists, "Pay with block should exist")
            payWithBlock.waitAndTap()
            return OnrampProvidersScreen(app)
        }
    }

    func tapCurrencySelector() -> OnrampCurrencySelectorScreen {
        XCTContext.runActivity(named: "Tap currency selector button (flag + chevron)") { _ in
            XCTAssertTrue(currencySelectorButton.waitForExistence(timeout: .longUIUpdate), "Currency selector button should exist")
            currencySelectorButton.waitAndTap()
            return OnrampCurrencySelectorScreen(app)
        }
    }

    @discardableResult
    func validateCurrencyChanged(expectedCurrency: String) -> Self {
        XCTContext.runActivity(named: "Validate currency changed to '\(expectedCurrency)'") { _ in
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "value CONTAINS %@", expectedCurrency),
                object: amountDisplayField
            )
            let result = XCTWaiter.wait(for: [expectation], timeout: 2.0)

            if result == .timedOut {
                XCTFail("Timeout waiting for currency to change to '\(expectedCurrency)'")
            }

            let actualValue = amountDisplayField.getValue()
            XCTAssertTrue(actualValue.contains(expectedCurrency), "Amount field should contain '\(expectedCurrency)' currency but was '\(actualValue)'")
        }
        return self
    }
}

enum OnrampScreenElement: String, UIElement {
    case title
    case closeButton
    case settingsButton
    case providerToSLink
    case cryptoAmountLabel
    case payWithBlock
    case currencySelectorButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return OnrampAccessibilityIdentifiers.title
        case .closeButton:
            return CommonUIAccessibilityIdentifiers.closeButton
        case .settingsButton:
            return OnrampAccessibilityIdentifiers.settingsButton
        case .providerToSLink:
            return OnrampAccessibilityIdentifiers.providerToSLink
        case .cryptoAmountLabel:
            return OnrampAccessibilityIdentifiers.cryptoAmountLabel
        case .payWithBlock:
            return OnrampAccessibilityIdentifiers.payWithBlock
        case .currencySelectorButton:
            return OnrampAccessibilityIdentifiers.currencySelectorButton
        }
    }
}
