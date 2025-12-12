//
//  MainScreenUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class MainScreenUITests: BaseTestCase {
    let token = "Polygon"

    func testHideToken_TokenNotDispayedOnMain() {
        setAllureId(880)
        launchApp(tangemApiType: .mock)

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .hideToken(name: token)

        mainScreen.validateTokenNotExists(token)
    }

    func testScanWallet2_DeveloperCardBannerDisplayed() {
        setAllureId(898)
        launchApp()

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)

        mainScreen.waitDeveloperCardBannerExists()
    }

    func testScanCardWithReleaseFirmware_DeveloperCardBannerNotDisplayed() {
        setAllureId(3991)
        launchApp()

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .ring)

        mainScreen.waitDeveloperCardBannerNotExists()
    }

    func testScanRing_MandatorySecurityUpdateBannerDisplayed() {
        setAllureId(227)
        launchApp()

        let mainScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2Imported)

        mainScreen.validateMandatorySecurityUpdateBannerExists()
    }
}
