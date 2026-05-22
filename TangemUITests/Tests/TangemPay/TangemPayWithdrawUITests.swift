//
//  TangemPayWithdrawUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayWithdrawUITests: BaseTestCase {
    func testWithdrawFromTangemPay_SwapsUSDCToBitcoin_AppendsWithdrawalToHistory() {
        setAllureId(4972)

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "bitcoin_utxo", initialState: "Started"),
            ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
            ScenarioConfig(name: "exchange_status_provider", initialState: "Changelly"),
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
            ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty"),
        ])

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains("$10.00")
            .tapWithdraw()
            .waitForScreen()
            .tapGotIt()
            .validateSwapScreenDisplayed()
            .chooseTokenFromEmptySelector("Bitcoin")
            .enterFromAmount("5")
            .confirmSwap()

        SendFinishScreen(app)
            .waitForDisplay()
            .tapCloseButton()

        wireMockClient.setScenarioStateSync("tangem_pay_balance_update", state: "AfterWithdraw")
        wireMockClient.setScenarioStateSync("tangem_pay_transaction_history", state: "AfterWithdraw")

        TangemPayMainScreen(app).waitForScreen()
        pullToRefresh()
        TangemPayMainScreen(app)
            .verifyBalanceContains("$5.00")
            .verifyTransactionRowVisible(label: "Withdrawal")
            .verifyPendingExpressTransactionVisible()
    }

    private func launchAndImportHotWallet(scenarios: [ScenarioConfig] = []) -> MainScreen {
        let eligibilityScenario = ScenarioConfig(
            name: "tangem_pay_eligibility",
            initialState: "PaeraCustomer"
        )

        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            visaApiType: .mock,
            clearStorage: true,
            scenarios: [eligibilityScenario] + scenarios
        )

        return CreateWalletSelectorScreen(app)
            .skipStories()
            .startWithMobileWallet()
            .tapImportButton()
            .enterSeedPhrase(TestSeedPhrases.hotWallet)
            .tapImportButton()
            .tapContinue()
            .skipAccessCode()
            .tapFinish()
    }
}
