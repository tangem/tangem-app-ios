//
//  BuyMarketPulseUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class BuyMarketPulseUITests: BaseTestCase {
    func testBuy_MarketPulseBlockDisplaysTopFiveTokens() {
        setAllureId(589)

        launchApp(tangemApiType: .mock, expressApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapMainBuy()
            .waitBuyTokenSelectorDisplayed()
            .waitMarketPulseTitleDisplayed()
            .waitMarketPulseTokensDisplayed(Constants.topTokens)
            .verifyMarketPulseTokenNotDisplayed(Constants.sixthToken)
    }
}

private extension BuyMarketPulseUITests {
    enum Constants {
        static let topTokens = ["Bitcoin", "Ethereum", "Tether", "XRP", "BNB"]
        static let sixthToken = "Solana"
    }
}
