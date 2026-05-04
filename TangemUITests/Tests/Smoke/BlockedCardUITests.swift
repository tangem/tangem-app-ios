//
//  BlockedCardUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class BlockedCardUITests: BaseTestCase {
    private let firstWalletName = "Wallet"

    func testBlockedCardWarning_DisplayedAndDismissedAfterUnlock() {
        setAllureId(188)

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .addNewWallet(name: .wallet)

        app.terminate()
        launchApp(tangemApiType: .mock, keepWallets: true)

        let authScreen = AuthScreen(app)
            .verifyScreenDisplayed()

        let mainScreen = authScreen
            .selectWallet(name: firstWalletName)
            .selectMockCard(name: .wallet2)

        mainScreen
            .swipeWalletLeft()
            .verifyWalletLockedNotificationExists()
            .verifyWalletLockedNotificationHasMessage()

        mainScreen
            .tapWalletLockedNotification()
            .selectMockCardFromScannerAlert(name: .wallet)
            .verifyWalletLockedNotificationNotExists()
    }
}
