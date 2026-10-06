//
//  TangemPayMultiWalletUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayMultiWalletUITests: BaseTestCase {
    func testSwitchingWallets_ShowsTangemPayDataOfSelectedWallet() {
        setAllureId(11642)

        let mainScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: Constants.Scenario.multiWallet, initialState: Constants.State.twoCustomers)]
        )
        .addNewWallet(name: .wallet2)

        verifyWalletBData(on: mainScreen)

        mainScreen.swipeWalletRight()
        verifyWalletAData(on: mainScreen)

        mainScreen.swipeWalletLeft()
        verifyWalletBData(on: mainScreen)
    }

    private func verifyWalletAData(on mainScreen: MainScreen) {
        mainScreen
            .verifyVisibleTangemPayTile(subtitle: Constants.WalletA.tileSubtitle, balance: Constants.WalletA.balance)
            .openVisibleTangemPay(subtitle: Constants.WalletA.tileSubtitle)
            .waitForScreen()
            .verifyBalanceContains(Constants.WalletA.balance)
            .verifyCardDisplayed(cardId: Constants.WalletA.cardId)
            .verifyCardNotDisplayed(cardId: Constants.WalletB.secondCardId)
            .verifyTransactionRow(name: Constants.WalletA.transaction)
            .verifyTransactionRowNotDisplayed(name: Constants.WalletB.transaction)
            .tapBack()
    }

    private func verifyWalletBData(on mainScreen: MainScreen) {
        mainScreen
            .verifyVisibleTangemPayTile(subtitle: Constants.WalletB.tileSubtitle, balance: Constants.WalletB.balance)
            .openVisibleTangemPay(subtitle: Constants.WalletB.tileSubtitle)
            .waitForScreen()
            .verifyBalanceContains(Constants.WalletB.balance)
            .verifyCardDisplayed(cardId: Constants.WalletB.firstCardId)
            .verifyCardDisplayed(cardId: Constants.WalletB.secondCardId)
            .verifyTransactionRow(name: Constants.WalletB.transaction)
            .verifyTransactionRowNotDisplayed(name: Constants.WalletA.transaction)
            .tapBack()
    }
}

private extension TangemPayMultiWalletUITests {
    enum Constants {
        enum Scenario {
            static let multiWallet = "tangem_pay_multi_wallet"
        }

        enum State {
            static let twoCustomers = "TwoCustomers"
        }

        enum WalletA {
            static let tileSubtitle = "*4242"
            static let balance = "$10.00"
            static let cardId = "mock-card-id"
            static let transaction = "Wallet A Shop"
        }

        enum WalletB {
            static let tileSubtitle = "2 cards"
            static let balance = "$250.00"
            static let firstCardId = "mock-card-id"
            static let secondCardId = "mock-card-id-2"
            static let transaction = "Wallet B Shop"
        }
    }
}
