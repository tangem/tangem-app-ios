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
