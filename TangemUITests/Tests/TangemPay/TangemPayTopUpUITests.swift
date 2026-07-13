//
//  TangemPayTopUpUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayTopUpUITests: BaseTestCase {
    func testTopUpFromTangemPay_SwapsBitcoinToUSDC_AppendsDepositToHistory() {
        setAllureId(4973)

        let mainScreen = launchAndImportHotWallet(expressApiType: .mock, scenarios: [
            ScenarioConfig(name: "bitcoin_utxo", initialState: "Balance"),
            ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
            ScenarioConfig(name: "exchange_status_provider", initialState: "Finished"),
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
            ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty"),
        ])

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains("$10.00")
            .tapAddFunds()
            .waitForScreen()
            .tapSwap()
            .validateSwapScreenDisplayed()
            .chooseTokenFromEmptySelector("Bitcoin")
            .enterFromAmount("0.001")
            .confirmSwap()

        SendFinishScreen(app)
            .waitForDisplay()
            .tapCloseButton()

        wireMockClient.setScenarioStateSync("tangem_pay_balance_update", state: "AfterDeposit")
        wireMockClient.setScenarioStateSync("tangem_pay_transaction_history", state: "AfterDeposit")

        TangemPayMainScreen(app).waitForScreen()
        pullToRefresh()
        TangemPayMainScreen(app)
            .verifyBalanceContains("$110.00")
            .verifyTransactionRowVisible(label: "Deposit")
    }
}
