//
//  BuyProvidersUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class BuyProvidersUITests: BaseTestCase {
    func testBuy_AllOffersSortedByReceiveAmount() {
        setAllureId(3719)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [ScenarioConfig(name: Constants.Scenario.onrampQuote, initialState: Constants.State.providersSorting)]
        )

        let onrampScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.token)
            .tapBuyButton()

        let mercuryoQuotesBefore = wireMockRequestCount(urlPattern: Constants.Endpoint.mercuryoQuote)
        let simplexQuotesBefore = wireMockRequestCount(urlPattern: Constants.Endpoint.simplexQuote)
        let cardQuotesBefore = wireMockRequestCount(urlPattern: Constants.Endpoint.cardQuote)

        let providersScreen = onrampScreen
            .enterAmount(Constants.amount)
            .waitForProvidersToLoad()
            .tapAllOffersButton()
            .selectPaymentMethod(id: Constants.cardPaymentMethod)

        waitForWireMockRequestCount(urlPattern: Constants.Endpoint.mercuryoQuote, toExceed: mercuryoQuotesBefore)
        waitForWireMockRequestCount(urlPattern: Constants.Endpoint.simplexQuote, toExceed: simplexQuotesBefore)
        waitForWireMockRequestCount(urlPattern: Constants.Endpoint.cardQuote, toExceed: cardQuotesBefore + 1)

        providersScreen
            .waitForProviders()
            .verifyProviderAmount(Constants.Provider.simplex, contains: Constants.Amount.simplex)
            .verifyProviderAmount(Constants.Provider.mercuryo, contains: Constants.Amount.mercuryo)
            .verifyProvider(Constants.Provider.simplex, isAbove: Constants.Provider.mercuryo)
    }

    func testBuy_OneProviderRestrictedIsMarkedUnavailable() {
        setAllureId(11588)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [ScenarioConfig(name: Constants.Scenario.onrampQuote, initialState: Constants.State.providerRestricted)]
        )

        let onrampScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.token)
            .tapBuyButton()
            .enterAmount(Constants.amount)
            .waitForProvidersToLoad()
            .verifyRegionRestrictionErrorNotDisplayed()

        onrampScreen
            .tapAllOffersButton()
            .selectPaymentMethod(id: Constants.cardPaymentMethod)
            .waitForProviders()
            .verifyRegionRestrictionNotificationDisplayed()
            .verifyProviderUnavailable(Constants.Provider.simplex)
            .verifyProviderAvailable(Constants.Provider.mercuryo)
    }
}

private extension BuyProvidersUITests {
    enum Constants {
        static let token = "Polygon"
        static let amount = "100"
        static let cardPaymentMethod = "card"

        enum Scenario {
            static let onrampQuote = "onramp_quote"
        }

        enum State {
            static let providersSorting = "ProvidersSorting"
            static let providerRestricted = "ProviderRestricted"
        }

        enum Provider {
            static let mercuryo = "Mercuryo"
            static let simplex = "Simplex"
        }

        enum Amount {
            static let mercuryo = "488.24938338"
            static let simplex = "520"
        }

        enum Endpoint {
            static let mercuryoQuote = "/v1/onramp-quote\\?.*providerId=mercuryo.*"
            static let simplexQuote = "/v1/onramp-quote\\?.*providerId=simplex.*"
            static let cardQuote = "/v1/onramp-quote\\?.*paymentMethod=card.*"
        }
    }
}
