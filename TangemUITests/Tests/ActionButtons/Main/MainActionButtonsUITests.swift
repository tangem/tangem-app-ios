//
//  MainActionButtonsUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class MainActionButtonsUITests: BaseTestCase {
    func testMainActionButtons_AreActiveAndNavigate() {
        setAllureId(4395)
        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
        )

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .tapMainBuy()
            .waitBuyTokenSelectorDisplayed()
            .tapCloseButton()

        mainScreen
            .tapMainSwap()
            .waitSwapTokenSelectorDisplayed()
            .tapCloseButton()

        mainScreen
            .tapMainSell()
            .waitSellTokenSelectorDisplayed()
            .tapCloseButton()
    }

    func testMainActionButtons_ShowErrorNotifications() {
        setAllureId(4398)
        let expressApiErrorScenario = ScenarioConfig(
            name: "express_api_assets",
            initialState: "Error"
        )

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: [expressApiErrorScenario]
        )

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)

        mainScreen.tapMainBuy()
        waitAndDismissErrorAlert(actionName: "Buy")

        mainScreen.tapMainSwap()
        waitAndDismissErrorAlert(actionName: "Exchange")
    }

    func testMainActionButtons_ShowErrorUnreachable() {
        setAllureId(4396)
        let expressApiErrorScenario = ScenarioConfig(
            name: "express_api_assets",
            initialState: "Unreachable"
        )

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: [expressApiErrorScenario]
        )

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)

        mainScreen.tapMainBuy()
        waitAndDismissErrorAlert(actionName: "Buy")

        mainScreen.tapMainSwap()
        waitAndDismissErrorAlert(actionName: "Exchange")
    }

    func testMainActionButtons_DisabledAfterEmptyTokensRefresh() {
        setAllureId(3642)

        let emptyTokensScenario = ScenarioConfig(
            name: "user_tokens_api",
            initialState: "EmptyTokensList"
        )

        launchApp(tangemApiType: .mock, clearStorage: true)

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)

        mainScreen
            .validate(cardType: .wallet2)
            .waitActionButtonsEnabled()

        setupWireMockScenarios([emptyTokensScenario])

        pullToRefresh()

        mainScreen.waitActionButtonsDisabled()
    }

    func testMainActionButtons_BuyBitcoin_OnrampScreenDisplayed() {
        setAllureId(895)
        let token = "Bitcoin"

        launchApp(
            tangemApiType: .mock,
            clearStorage: true,
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .validate(cardType: .wallet2)
            .tapMainBuy()
            .waitBuyTokenSelectorDisplayed()
            .tapToken(token)
            .waitForTitle("Buy \(token)")
    }
}
