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
        id(2566)
        let expectedAmount = "0"
        let expectedCurrency = "€"
        let expectedTitle = "Buy \(token)"

        launchApp(tangemApiType: .mock)

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapActionButton(.buy)
            .tapCurrencySelector()
            .selectCurrency("EUR")
            .validate(amount: expectedAmount, currency: expectedCurrency, title: expectedTitle)
            .enterAmount(amountToEnter)
            .validateCryptoAmount()
            .hideKeyboard()
            .validateProviderToSLinkExists()
    }

    func testGoOnramp_validateProvidersScreen() {
        id(2570)
        launchApp(tangemApiType: .mock)

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapActionButton(.buy)
            .enterAmount(amountToEnter)
            .waitForProvidersToLoad()
            .tapPayWithBlock()
            .validate()
            .validateAnyProviderCard()
            .tapCloseButton()
    }

    func testGoOnramp_validateCurrencySelector() {
        id(2565)
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
                amount: amountToEnter,
                currency: newCurrencySymbol,
                title: "Buy \(token)"
            )
    }

    func testGoOnramp_validateResidenceSelection() {
        id(2563)
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
                amount: amountToEnter,
                currency: "$",
                title: "Buy \(token)"
            )
    }

    func testGoOnramp_validatePaymentMethodsSelection() {
        id(3479)
        let amountToEnter = "100"

        launchApp(tangemApiType: .mock)

        let (returnedProvidersScreen, selectedPaymentMethodId) = StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapActionButton(.buy)
            .enterAmount(amountToEnter)
            .waitForProvidersToLoad()
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

    func testGoOnramp_paymentMethodsErrorShowed() {
        id(3478)
        let errorScenario = ScenarioConfig(
            name: "payment_methods",
            initialState: "Error"
        )

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [errorScenario]
        )

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapActionButton(.buy)
            .enterAmount(amountToEnter)
            .validateErrorViewExists()
    }
}
