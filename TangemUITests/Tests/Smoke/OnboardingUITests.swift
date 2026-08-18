//
//  OnboardingUITests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class OnboardingUITests: BaseTestCase {
    func testScanShibaNoBackupCard_ShowsCreateBackupScreen() {
        setAllureId(3989)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .shibaNoBackup)

        CreateBackupScreen(app)
            .validateScreen()
    }

    func testScanWallet2NoBackupCard_ShowsCreateBackupScreen() {
        setAllureId(3990)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2NoBackup)

        CreateBackupScreen(app)
            .validateScreen()
    }

    func testScanShibaNoBackupCard_ShowsCreateWalletScreenWithoutSkipButton() {
        setAllureId(248)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .shibaNoWallets)

        CreateWalletScreen(app)
            .validateScreen(by: .shibaNoWallets)
    }

    func testScanWallet2NoBackupCard_ShowsCreateWalletScreenWithoutSkipButton() {
        setAllureId(246)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2NoWallets)

        CreateWalletScreen(app)
            .validateScreen(by: .wallet2NoWallets)
    }

    func testScanWallet3NoBackupCard_ShowsCreateBackupScreen() {
        setAllureId(10820)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet3NoBackup)

        CreateBackupScreen(app)
            .validateScreen()
    }

    func testScanWallet3NoWalletsCard_ShowsCreateWalletScreenWithoutSkipButton() {
        setAllureId(10816)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet3NoWallets)

        CreateWalletScreen(app)
            .validateScreen(by: .wallet3NoWallets)
    }
}
