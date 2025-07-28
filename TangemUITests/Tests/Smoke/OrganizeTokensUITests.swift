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
        id(2752)
        launchApp(tangemApiType: .mock)

        let mainTokensOrder = StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .getTokensOrder()

        MainScreen(app)
            .organizeTokens()
            .verifyTokensOrder(mainTokensOrder)
    }

    func testSortTokensByBalance_TokensSortedOnMain() {
        id(2754)
        let expectedTokensOrder: [String] = ["Polygon", "Bitcoin", "Ethereum"]
        launchApp(tangemApiType: .mock)

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .organizeTokens()
            .sortByBalance()
            .verifyTokensOrder(expectedTokensOrder)

        OrganizeTokensScreen(app)
            .applyChanges()
            .verifyTokensOrder(expectedTokensOrder)
    }

    func testChangeTokensOrder_TokensOrderChangedOnMain() {
        id(2753)
        let expectedTokensOrder: [String] = ["Bitcoin", "Polygon", "Ethereum"]
        launchApp(tangemApiType: .mock)

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .organizeTokens()
            .drag(one: "Polygon", to: "Ethereum")
            .verifyTokensOrder(expectedTokensOrder)

        OrganizeTokensScreen(app)
            .applyChanges()
            .verifyTokensOrder(expectedTokensOrder)
    }

    func testGroupUngroup_TokensGroupedAndUngroupedCorrectly() {
        id(2755)
        launchApp(tangemApiType: .mock)

        let organizeTokensScreen = StoriesScreen(app)
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
