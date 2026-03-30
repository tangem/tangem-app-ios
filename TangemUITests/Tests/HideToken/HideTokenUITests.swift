//
//  HideTokenUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//

import XCTest

final class HideTokenUITests: BaseTestCase {
    func testHideTokenViaLongTap_TokenNotDisplayedOnMain() {
        setAllureId(3638)
        launchApp(tangemApiType: .mock)

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken("Polygon")
            .tapHideToken(tokenName: "Polygon")

        mainScreen.validateTokenNotExists("Polygon")
    }

    func testHideTokenViaManageTokens_TokenNotDisplayedOnMain() {
        setAllureId(3627)
        let scenario = ScenarioConfig(name: "user_tokens_api", initialState: "USDT")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings(for: "Wallet")
            .selectAccount("Main account")
            .openManageTokens()
            .expandTokenIfNeeded(coinId: "tether")
            .toggleOffNetwork("Ethereum")
            .confirmHideTokenAlert(tokenName: "Tether")
            .tapSaveButton()
            .goBackToAccountSettings()
            .goBackToWalletSettings()
            .goBackToDetails()
            .goBackToMain()
            .validateTokenNotExists("Tether")
    }

    func testHideMainCoinViaManageTokens_CoinNotDisplayedOnMain() {
        setAllureId(3626)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings(for: "Wallet")
            .selectAccount("Main account")
            .openManageTokens()
            .expandTokenIfNeeded(coinId: "polygon-ecosystem-token")
            .toggleOffNetwork("Polygon")
            .confirmHideTokenAlert(tokenName: "Polygon")
            .tapSaveButton()
            .goBackToAccountSettings()
            .goBackToWalletSettings()
            .goBackToDetails()
            .goBackToMain()
            .validateTokenNotExists("Polygon")
    }

    func testHideMainCoinWithSubTokens_UnableToHideAlertShown() {
        setAllureId(3610)
        let scenario = ScenarioConfig(name: "user_tokens_api", initialState: "USDT")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken("Ethereum")
            .tapHideTokenExpectingUnableAlert(tokenName: "Ethereum")
    }
}
