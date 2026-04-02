//
//  OrganizeTokensUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class OrganizeTokensUITests: BaseTestCase {
    func testCheckOrganizeTokensOrder_TheSameOrderAsOnMain() {
        setAllureId(2752)
        launchApp(tangemApiType: .mock)

        let mainTokensOrder = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .getTokensOrder()

        MainScreen(app)
            .organizeTokens()
            .verifyTokensOrder(mainTokensOrder)
    }

    func testSortTokensByBalance_TokensSortedOnMain() {
        setAllureId(2754)
        let expectedTokensOrder: [String] = ["Ethereum", "POL (ex-MATIC)", "Polygon", "Bitcoin"]
        let expected: TokensOrder = .mainAccount(expectedTokensOrder)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .organizeTokens()
            .sortByBalance()
            .verifyTokensOrder(expected)

        OrganizeTokensScreen(app)
            .applyChanges()
            .verifyTokensOrder(expected)
    }

    func testChangeTokensOrder_TokensOrderChangedOnMain() {
        setAllureId(2753)
        let expectedTokensOrder: [String] = ["Bitcoin", "Polygon", "Ethereum", "POL (ex-MATIC)"]
        let expected: TokensOrder = .mainAccount(expectedTokensOrder)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .organizeTokens()
            .drag(one: "Polygon", to: "Ethereum")
            .verifyTokensOrder(expected)

        OrganizeTokensScreen(app)
            .applyChanges()
            .verifyTokensOrder(expected)
    }

    // MARK: - Organize Tokens Button Visibility

    func testOrganizeTokensButtonVisible_MultipleTokensNoAccounts() {
        setAllureId(66)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .verifyOrganizeTokensButtonVisible()
    }

    func testOrganizeTokensButtonHidden_SingleTokenNoAccounts() {
        setAllureId(8748)
        let scenario = ScenarioConfig(name: "user_tokens_api", initialState: "Cardano")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .verifyOrganizeTokensButtonNotVisible()
    }

    func testOrganizeTokensButtonHidden_MultiAccountSingleTokenEach() {
        setAllureId(8749)
        let scenario = ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSingleTokenEach")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .verifyOrganizeTokensButtonNotVisible()
    }

    func testOrganizeTokensButtonVisible_MultiAccountMultipleTokensInOne() {
        setAllureId(8750)
        let scenario = ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsMixed")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .verifyOrganizeTokensButtonVisible()
    }

    func testOrganizeTokensListMatchesCurrentWallet_WhenSwitchingBetweenCards() {
        setAllureId(71)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .addNewWallet(name: .wallet)

        let mainScreen = MainScreen(app)
            .swipeWalletRight()

        let card1TokensOrder = mainScreen.getTokensOrder()

        mainScreen
            .organizeTokens()
            .verifyTokensOrder(card1TokensOrder)

        OrganizeTokensScreen(app)
            .cancelOrganizeTokens()
            .swipeWalletLeft()

        let card2MainScreen = MainScreen(app)
        card2MainScreen.verifyOrganizeTokensButtonVisible()

        let card2TokensOrder = card2MainScreen.getTokensOrder()

        card2MainScreen
            .organizeTokens()
            .verifyTokensOrder(card2TokensOrder)
    }

    // MARK: - Grouping

    func testGroupUngroup_TokensGroupedAndUngroupedCorrectly() {
        setAllureId(2755)
        launchApp(tangemApiType: .mock)

        let organizeTokensScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .organizeTokens()
            .verifyIsGrouped(false)
            .group()
            .verifyIsGrouped(true)

        let mainScreen = organizeTokensScreen.applyChanges()

        mainScreen.verifyIsGrouped(true)

        let organizeTokensScreenAfterGroup = mainScreen
            .organizeTokens()
            .verifyIsGrouped(true)
            .verifyGroupingButtonState(expectedToShowUngroup: true)
            .ungroup()
            .verifyIsGrouped(false)
            .verifyGroupingButtonState(expectedToShowUngroup: false)

        let mainScreenAfterUngroup = organizeTokensScreenAfterGroup.applyChanges()

        mainScreenAfterUngroup.verifyIsGrouped(false)
    }
}
