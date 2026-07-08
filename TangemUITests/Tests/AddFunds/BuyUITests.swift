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

    func testBuy_CorrectInfoDisplayingOnProviderSide() {
        setAllureId(3614)
        let token = "Bitcoin"
        let amount = 50
        let scenario = ScenarioConfig(
            name: "onramp_widget",
            initialState: "Mercuryo"
        )

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            scenarios: [scenario]
        )

        let receiveSheet = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapReceiveButton()
            .tapUnderstoodIfNeeded()

        let receivingAddress = receiveSheet.readSegwitAddress()

        receiveSheet
            .close()
            .tapBuyButton()
            .enterAmount(String(amount))
            .waitForProvidersToLoad()
            .tapAnyBuyButton()
            .tapOffer(fiatAmount: amount)
            .verifyTotalPaidAmountMatches(amount)
            .verifyReceivingWalletMatches(receivingAddress)
    }

    func testBuy_S2CCardShowsBuyAndSellButNotSwap() {
        setAllureId(3613)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .s2c)
            .verifySingleCurrencyWalletActionButtons()
    }
}
