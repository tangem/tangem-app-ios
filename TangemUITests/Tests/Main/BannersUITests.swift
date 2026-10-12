//
//  BannersUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class BannersUITests: BaseTestCase {
    func testBanners_noteBannerContentsLinkWithPromoCode() {
        setAllureId(214)

        launchApp(tangemApiType: .mock)
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .xrpNote)
            .verifyPromoBannerTitleVisible()
            .verifyPromoBannerBodyVisible()
            .tapPromoBannerButton()
            .waitForBrowserOpened()
    }

    /// Banner is still displayed after a wallet is added; app relaunch is required.
    func skipped_testBanners_noteBannerIsNotDisplayIfWalletAdded() {
        setAllureId(4027)
        let secondWallet = "Wallet"

        launchApp(tangemApiType: .mock)
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .xrpNote)
            .verifyPromoBannerTitleVisible()
            .verifyPromoBannerBodyVisible()
            .addNewWallet(name: .wallet2)
            .swipeWalletRight()
            .verifyPromoBannerTitleIsNotVisible()
            .forgetWallet(secondWallet)
            .tapBackButton(to: MainScreen.self)
            .verifyPromoBannerTitleVisible()
    }
}
