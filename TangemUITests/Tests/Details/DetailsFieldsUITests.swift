//
//  DetailsFieldsUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class DetailsFieldsUITests: BaseTestCase {
    func testDetailsFields_Twins() {
        setAllureId(840)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .twin)
            .openDetails()
            .verifySections(walletConnect: false)
    }

    func testDetailsFields_Note() {
        setAllureId(837)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .xrpNote)
            .openDetails()
            .verifySections(walletConnect: false)
    }

    func testDetailsFields_Wallet() {
        setAllureId(836)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .verifySections(walletConnect: true)
    }

    func testDetailsFields_V412() {
        setAllureId(839)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .four12)
            .openDetails()
            .verifySections(walletConnect: true)
    }

    func testDetailsFields_V3Multi() {
        setAllureId(838)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .v3seckp)
            .openDetails()
            .verifySections(walletConnect: true)
    }

    func testDetailsFields_SingleCurrency() {
        setAllureId(9832)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .xlmBird)
            .openDetails()
            .verifySections(walletConnect: false)
    }

    func testDetailsFields_S2C() {
        setAllureId(841)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .s2c)
            .openDetails()
            .verifySections(walletConnect: false)
    }

    func testS2C_NoTradeButtonsAndStandardDetails() {
        setAllureId(2869)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .s2c)
            .verifyTradeActionButtonsHidden()
            .openDetails()
            .verifySections(walletConnect: false)
    }

    func testToSScreenDisplaying() {
        setAllureId(222)
        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openToSScreen()
            .verifyTitle()
            .verifyWebViewLoaded()
            .verifyToSText()
    }
}
