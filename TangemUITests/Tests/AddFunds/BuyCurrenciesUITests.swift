//
//  BuyCurrenciesUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class BuyCurrenciesUITests: BaseTestCase {
    func testBuy_CurrenciesListNotReceivedShowsErrorAndRetries() {
        setAllureId(11991)

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [ScenarioConfig(name: Constants.Scenario.currencies, initialState: Constants.State.error)]
        )

        let onrampScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.token)
            .tapBuyButton()

        let requestsBeforeOpen = wireMockRequestCount(urlPattern: Constants.Endpoint.currencies)

        let selectorScreen = onrampScreen
            .tapCurrencySelector()
            .waitForLoadError()

        waitForWireMockRequestCount(urlPattern: Constants.Endpoint.currencies, toExceed: requestsBeforeOpen)
        let requestsBeforeRetry = wireMockRequestCount(urlPattern: Constants.Endpoint.currencies)

        selectorScreen
            .tapTryAgain()
            .waitForLoadError()

        waitForWireMockRequestCount(urlPattern: Constants.Endpoint.currencies, toExceed: requestsBeforeRetry)
    }
}

private extension BuyCurrenciesUITests {
    enum Constants {
        static let token = "Polygon"

        enum Scenario {
            static let currencies = "currencies_api"
        }

        enum State {
            static let error = "Error"
        }

        enum Endpoint {
            static let currencies = "/v1/currencies"
        }
    }
}
