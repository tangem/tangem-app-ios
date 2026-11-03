//
//  AddNetworkViaMarketsE2ETests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class AddNetworkViaMarketsE2ETests: E2EBaseTestCase {
    func testAddNetworkToMainViaMarkets() {
        setAllureId(2068)

        let (main, network) = launchAndImportE2EWallet()

        main
            .openMarketsSheet()
            .searchForToken(network.searchQuery)
            .tapTokenInSearchResults(network.tokenName)
            .tapAddToPortfolioButton()
            .selectNetwork(network.networkName)
            .tapAddTokenButton()
            .tapGetTokenLaterButton()
            .closeMarketsSheetWithSwipe()
            .revealToken(network.mainScreenToken)
            .verifyTokenVisible(network.mainScreenToken)
            .verifyTokenBalanceNonNegative(network.mainScreenToken)
    }
}
