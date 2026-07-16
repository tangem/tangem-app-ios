//
//  AppCurrencyUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class AppCurrencyUITests: BaseTestCase {
    private let targetCurrency = "EUR"
    private let targetSymbol = "€"
    private let token = "Polygon"

    func testChangeAppCurrency_UpdatesEquivalentEverywhere() {
        setAllureId(781)
        let currencyScenario = ScenarioConfig(
            name: "currencies_api",
            initialState: "AppSettings"
        )

        launchApp(
            tangemApiType: .mock,
            scenarios: [currencyScenario]
        )

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)

        mainScreen
            .openDetails()
            .openAppSettings()
            .tapCurrencyButton()
            .validateScreenElements()
            .selectCurrency(targetCurrency)
            .goBackToDetails()
            .goBackToMain()
            .waitForTotalBalanceContainsCurrency(targetSymbol)
            .tapToken(token)
            .waitForTotalBalanceContainsCurrency(targetSymbol)
    }
}
