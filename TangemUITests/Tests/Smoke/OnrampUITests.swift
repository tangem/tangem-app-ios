//
//  OnrampUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class OnrampUITests: BaseTestCase {
    let token = "Polygon"
    let amountToEnter = "100"

    func testGoOnramp_validateScreen() {
        let expectedTextFieldValue = "0 €"
        let expectedTitle = "Buy \(token)"

        launchApp(tangemApiType: .mock)

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapActionButton(.buy)
            .tapCurrencySelector()
            .selectCurrency("EUR")
            .validate(textFieldValue: expectedTextFieldValue, title: expectedTitle)
            .enterAmount(amountToEnter)
            .validateCryptoAmount()
            .validateProviderToSLinkExists()
    }

    func testGoOnramp_validateProvidersScreen() {
        launchApp(tangemApiType: .mock)

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapActionButton(.buy)
            .enterAmount(amountToEnter)
            .tapPayWithBlock()
            .validate()
            .validateAnyProviderCard()
            .tapCloseButton()
    }

    func testGoOnramp_validateCurrencySelector() {
        let newCurrency = "USD"
        let newCurrencySymbol = "$"

        launchApp(tangemApiType: .mock)

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapActionButton(.buy)
            .enterAmount(amountToEnter)
            .tapCurrencySelector()
            .validate()
            .validateCurrencyExists(newCurrency)
            .selectCurrency(newCurrency)
            .validateCurrencyChanged(expectedCurrency: newCurrencySymbol)
            .validate(
                textFieldValue: "\(amountToEnter) \(newCurrencySymbol)",
                title: "Buy \(token)"
            )
    }

    func testGoOnramp_validateResidenceSelection() {
        let countryToSelect = "United States of America"

        launchApp(tangemApiType: .mock)

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapActionButton(.buy)
            .enterAmount(amountToEnter)
            .tapSettingsButton()
            .tapResidenceButton()
            .validateResidenceScreenOpened()
            .searchForCountry(countryToSelect)
            .selectCountry(countryToSelect)
            .validateSelectedCountry(countryToSelect)
            .dismissOnrampSettings()
            .validate(
                textFieldValue: "\(amountToEnter) $",
                title: "Buy \(token)"
            )
    }

    func testGoOnramp_validatePaymentMethodsSelection() {
        let amountToEnter = "100"

        launchApp(tangemApiType: .mock)

        let (returnedProvidersScreen, selectedPaymentMethodId) = StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapActionButton(.buy)
            .enterAmount(amountToEnter)
            .tapPayWithBlock()
            .validateScreenTitle()
            .validateProviderIconsAndNames()
            .tapPaymentMethodBlock()
            .validate()
            .validatePaymentMethodIconsAndNames()
            .selectPaymentMethod(at: 1)

        returnedProvidersScreen
            .validateSelectedPaymentMethod(selectedPaymentMethodId)
            .validateScreenTitle()
    }
}
