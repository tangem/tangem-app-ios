//
//  TangemPayDeactivatedAccountUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayDeactivatedAccountUITests: BaseTestCase {
    func testMainTileShowsAccountClosed_WhenAccountIsDeactivated() {
        setAllureId(9714)

        launchWithDeactivatedAccount()
            .verifyTangemPayTileSubtitle(Constants.Text.accountClosed)
    }

    func testPaymentAccountShowsClosedAccountBlock_WhenAccountIsDeactivated() {
        setAllureId(9715)

        launchWithDeactivatedAccount()
            .openTangemPay()
            .verifyAccountClosedBannerDetails()
    }

    func testTopUpViaSwap_Succeeds_WhenAccountIsDeactivated() {
        setAllureId(9719)

        launchWithDeactivatedAccount(
            expressApiType: .mock,
            extraScenarios: [
                ScenarioConfig(name: Constants.Scenario.bitcoinUtxo, initialState: Constants.State.bitcoinBalance),
                ScenarioConfig(name: Constants.Scenario.expressAssets, initialState: Constants.State.bitcoinExchangeEnabled),
                ScenarioConfig(name: Constants.Scenario.exchangeStatus, initialState: Constants.State.exchangeFinished),
                ScenarioConfig(name: Constants.Scenario.history, initialState: Constants.State.emptyHistory),
            ]
        )
        .openTangemPay()
        .verifyAccountClosedBanner()
        .tapAddFunds()
        .waitForScreen()
        .tapSwap()
        .validateSwapScreenDisplayed()
        .chooseSourceToken(Constants.Token.bitcoin)
        .enterFromAmount(Constants.Token.bitcoinTopUpAmount)
        .confirmSwap()

        SendFinishScreen(app)
            .waitForDisplay()
            .tapCloseButton()

        TangemPayMainScreen(app)
            .verifyAccountClosedBanner()
    }

    private func launchWithDeactivatedAccount(
        expressApiType: ExpressAPI? = nil,
        extraScenarios: [ScenarioConfig] = []
    ) -> MainScreen {
        launchAndImportHotWallet(
            expressApiType: expressApiType,
            scenarios: [ScenarioConfig(name: Constants.Scenario.accountRemoval, initialState: Constants.State.deactivated)] + extraScenarios
        )
    }
}

private extension TangemPayDeactivatedAccountUITests {
    enum Constants {
        enum Scenario {
            static let accountRemoval = "tangem_pay_account_removal"
            static let bitcoinUtxo = "bitcoin_utxo"
            static let expressAssets = "express_api_assets"
            static let exchangeStatus = "exchange_status_provider"
            static let history = "tangem_pay_transaction_history"
        }

        enum State {
            static let deactivated = "Deactivated"
            static let bitcoinBalance = "Balance"
            static let bitcoinExchangeEnabled = "BitcoinExchangeEnabled"
            static let exchangeFinished = "Finished"
            static let emptyHistory = "InitialEmpty"
        }

        enum Token {
            static let bitcoin = "Bitcoin"
            static let bitcoinTopUpAmount = "0.001"
        }

        enum Text {
            static let accountClosed = "Account closed"
        }
    }
}
