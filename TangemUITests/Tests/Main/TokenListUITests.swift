//
//  TokenListUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TokenListUITests: BaseTestCase {
    func testTokenList_tokenListDisplayedForMulticurrencyWallets() {
        setAllureId(168)
        let multicurrencyCards: [CardMockAccessibilityIdentifiers] = [
            .wallet2, .wallet, .v3seckp, .four12,
        ]

        for card in multicurrencyCards {
            XCTContext.runActivity(named: "Card \(card.rawValue)") { _ in
                launchApp(tangemApiType: .mock)
                CreateWalletSelectorScreen(app)
                    .scanMockWallet(name: card)
                    .organizeTokens()
                    .assertOrganizeTokensSheetIsDisplayed()
            }
        }
    }

    func testTokenList_addAndManageUnavailableForSingleCurrencyCard() {
        setAllureId(169)
        let singleCurrencyCards: [CardMockAccessibilityIdentifiers] = [
            .twin, .s2c, .xrpNote,
        ]

        for card in singleCurrencyCards {
            XCTContext.runActivity(named: "Card \(card.rawValue)") { _ in
                launchApp(tangemApiType: .mock)
                CreateWalletSelectorScreen(app)
                    .scanMockWallet(name: card)
                    .verifyTokenCount(1)
                    .verifyOrganizeTokensButtonNotVisible()
            }
        }
    }

    func testTokenList_tokenListDisplayedForNodlWallet() {
        setAllureId(170)

        launchApp(tangemApiType: .mock)
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .nodl)
            .verifyTokenCount(2)
            .verifyOrganizeTokensButtonNotVisible()
    }

    func testTokenList_contextMenuDisplayed() {
        setAllureId(176)
        let bitcoinExchangeScenario = ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled")
        let bitcoinBalanceScenario = ScenarioConfig(name: "bitcoin_utxo", initialState: "Balance")
        let derivedTokenTitle = "Bitcoin"
        let missedDerivationTokenTitle = "Ethereum"

        launchApp(tangemApiType: .mock, expressApiType: .mock, scenarios: [bitcoinExchangeScenario, bitcoinBalanceScenario])
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2PartialDerivations)
            .waitForSynchronizeAddressesButtonExists()
            .openTokenContextMenu(derivedTokenTitle)
            .assertActions(ContextMenuScreen.derivedTokenActions, exact: false)
            .dismiss()
            .openTokenContextMenu(missedDerivationTokenTitle)
            .assertActions(ContextMenuScreen.underivedTokenActions)
    }

    func testTokenList_emptyTokenListIsDisplayed() {
        setAllureId(178)
        let userTokenScenario = ScenarioConfig(name: "user_tokens_api", initialState: "EmptyTokensList")

        launchApp(tangemApiType: .mock, scenarios: [userTokenScenario])
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .verifyAddTokensButtonVisible()
            .verifyMarketsSheetIsCollapsedOnMain()
    }

    func testTokenList_customIconInTokenList() {
        setAllureId(180)
        let userTokensScenario = ScenarioConfig(name: "user_tokens_api", initialState: "CustomDerivation")
        let networkTitle = "Ethereum"
        let customTokenTitle = "Myria"

        launchApp(tangemApiType: .mock, scenarios: [userTokensScenario])
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .verifyTokenVisible(networkTitle)
            .verifyCustomTokenIndicatorExists(for: customTokenTitle)
    }

    func testTokenList_customIconOnTokenDetailsScreen() {
        setAllureId(181)
        let userTokensScenario = ScenarioConfig(name: "user_tokens_api", initialState: "CustomDerivation")
        let customTokenName = "Myria"

        launchApp(tangemApiType: .mock, scenarios: [userTokensScenario])
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .verifyCustomTokenIndicatorExists(for: customTokenName)
            .tapToken(customTokenName)
            .verifyCustomTokenIndicatorExists()
    }
}
