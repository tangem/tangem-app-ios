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
}
