//
//  BuyUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class BuyUITests: BaseTestCase {
    func testBuy_AvailableForBuyTokensDisplaying() {
        setAllureId(587)
        let token = "Bitcoin"

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapMainBuy()
            .waitBuyTokenSelectorDisplayed()
            .tapToken(token)
            .tapBuy()
            .waitForTitle("Buy " + token)
    }

    func testBuy_AddingTrendingTokenToMainScreen() {
        setAllureId(590)
        let token = "Tether"

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapMainBuy()
            .waitBuyTokenSelectorDisplayed()
            .tapTrendingToken(token)
            .tapAddToPortfolio()
            .tapAddTokenButton()
            .waitForTokenAddedToastOnMarketsTokenDetails()
            .tapBackButton()
            .waitTokenInWalletSection(token)
    }
}
