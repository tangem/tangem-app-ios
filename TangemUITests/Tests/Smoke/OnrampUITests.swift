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

    func testGoOnramp_validateScreen() throws {
        setAllureId(2566)
        let expectedAmount = ""
        let expectedCurrency = "€"
        let expectedTitle = "Buy \(token)"

        launchApp(tangemApiType: .mock)

        try CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapBuyButton()
            .tapCurrencySelector()
            .selectCurrency("EUR")
            .waitForAmountFieldDisplay(
                amount: expectedAmount,
                currency: expectedCurrency,
                title: expectedTitle
            )
            .enterAmount(amountToEnter)
            .waitForCryptoAmountRounding()
    }

    func testGoOnramp_validateProvidersScreen() {
        setAllureId(2570)
        launchApp(tangemApiType: .mock)

        let providersAfterSelection = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapBuyButton()
            .enterAmount(amountToEnter)
            .waitForProvidersToLoad()
            .tapAllOffersButton()
            .waitForPaymentMethodIconsAndNames()
            .selectPaymentMethod()

        providersAfterSelection
            .waitForProviders()
            .waitForProviderIconsAndNames()
            .waitForProviderCard()
            .waitForBuyButtons()
            .tapAnyBuyButtonAndValidateWebView()
            .tapCloseButton()
    }

    func testGoOnramp_validateCurrencySelector() throws {
        setAllureId(2565)
        let newCurrency = "USD"
        let newCurrencySymbol = "$"

        launchApp(tangemApiType: .mock)

        try CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapBuyButton()
            .enterAmount(amountToEnter)
            .tapCurrencySelector()
            .validate()
            .validateCurrencyExists(newCurrency)
            .selectCurrency(newCurrency)
            .validateCurrencyChanged(expectedCurrency: newCurrencySymbol)
            .waitForAmountFieldDisplay(
                amount: amountToEnter,
                currency: newCurrencySymbol,
                title: "Buy \(token)"
            )
    }

    func testGoOnramp_validateResidenceSelection() throws {
        setAllureId(2563)
        let countryToSelect = "United States of America"

        launchApp(tangemApiType: .mock)

        try CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapBuyButton()
            .enterAmount(amountToEnter)
            .tapSettingsButton()
            .tapResidenceButton()
            .validateResidenceScreenOpened()
            .searchForCountry(countryToSelect)
            .selectCountry(countryToSelect)
            .validateSelectedCountry(countryToSelect)
            .dismissOnrampSettings()
            .waitForAmountFieldDisplay(
                amount: amountToEnter,
                currency: "$",
                title: "Buy \(token)"
            )
    }

    func testGoOnramp_validatePaymentMethodsSelection() {
        setAllureId(3479)
        let amountToEnter = "100"

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapBuyButton()
            .enterAmount(amountToEnter)
            .waitForProvidersToLoad()
            .tapAllOffersButton()
            .waitForPaymentMethodIconsAndNames()
            .selectPaymentMethod()
            .waitForProviders()
            .waitForBuyButtons()
            .waitForProviderIconsAndNames()
    }

    func testGoOnramp_paymentMethodsErrorShowed() {
        setAllureId(3478)
        let errorScenario = ScenarioConfig(
            name: "payment_methods",
            initialState: "Error"
        )

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [errorScenario]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapBuyButton()
            .enterAmount(amountToEnter)
            .waitForErrorView()
    }
}
