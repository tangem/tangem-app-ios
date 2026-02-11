//
//  MarketsSecurityScoreUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class MarketsSecurityScoreUITests: BaseTestCase {
    func testMarketsSecurityScoreBlockDisplayed() {
        setAllureId(63)
        let tokenName = "Bitcoin"

        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(tokenName)
            .openTokenDetails(tokenName)
            .verifySecurityScoreBlockDisplayed()
            .verifySecurityScoreValue()
            .verifySecurityScoreReviewsCount()
            .verifySecurityScoreRatingStars()
    }

    func testMarketsSecurityScoreDetailsNavigation() {
        setAllureId(64)
        let tokenName = "Bitcoin"

        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(tokenName)
            .openTokenDetails(tokenName)
            .openSecurityScoreDetails()
            .verifyDetailsSheetDisplayed()
            .tapFirstProviderLink()
    }

    func testMarketsSecurityScoreBlockHidden() {
        setAllureId(65)
        let tokenName = "PepeTopia"

        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheetWithSwipe()
            .searchForToken(tokenName)
            .openTokenDetails(tokenName)
            .verifySecurityScoreBlockHidden()
    }
}
