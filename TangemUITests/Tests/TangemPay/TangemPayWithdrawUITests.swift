//
//  TangemPayWithdrawUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayWithdrawUITests: BaseTestCase {
    /// CEX withdraw submits via Express, not /customer/card/withdraw; assert single swap submission on this endpoint.
    private static let exchangeSentEndpointPattern = "/v1/exchange-sent"

    func testWithdrawFromTangemPay_SwapsUSDCToBitcoin_AppendsWithdrawalToHistory() {
        setAllureId(4972)

        openWithdrawSwapScreen()
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

    func testWithdrawButtonDisabled_WhenBalanceIsZero() {
        setAllureId(10099)

        launchAndImportHotWallet(expressApiType: .mock)
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains("$0.00")
            .verifyWithdrawDisabled()
    }

    func testWithdraw_InsufficientFunds_ShowsError() {
        setAllureId(9599)

        openWithdrawSwapScreen()
            .chooseTokenFromEmptySelector("Bitcoin")
            .enterFromAmount("20")
            .waitForInsufficientFundsError()
    }

    func testWithdraw_DisplaysCorrectCexProvider() {
        setAllureId(9602)

        openWithdrawSwapScreen()
            .chooseTokenFromEmptySelector("Bitcoin")
            .enterFromAmount("5")
            .verifyProviderName(contains: "Changelly")
    }

    func testWithdraw_SwapConfirm_SubmitsExchangeOnce() {
        setAllureId(9607)

        let swapScreen = openWithdrawSwapScreen()
            .chooseTokenFromEmptySelector("Bitcoin")
            .enterFromAmount("5")

        let before = exchangeSentRequestCount()
        swapScreen.confirmSwap()
        SendFinishScreen(app).waitForDisplay()

        XCTContext.runActivity(named: "Verify swap was submitted exactly once") { _ in
            let after = exchangeSentRequestCount()
            XCTAssertEqual(after - before, 1, "Swap should be submitted exactly once, but delta was \(after - before)")
        }
    }

    func testFullWithdraw_ZeroesBalance_AppendsToHistory() {
        setAllureId(9600)

        openWithdrawSwapScreen()
            .chooseTokenFromEmptySelector("Bitcoin")
            .tapMaxAmountFraction()
            .waitForFromAmountIsNotZero()
            .confirmSwap()

        SendFinishScreen(app)
            .waitForDisplay()
            .tapCloseButton()

        wireMockClient.setScenarioStateSync("tangem_pay_balance_update", state: "AfterFullWithdraw")
        wireMockClient.setScenarioStateSync("tangem_pay_transaction_history", state: "AfterFullWithdraw")

        TangemPayMainScreen(app).waitForScreen()
        pullToRefresh()
        TangemPayMainScreen(app)
            .verifyBalanceContains("$0.00")
            .verifyTransactionRowVisible(label: "Withdrawal")
            .verifyPendingExpressTransactionVisible()
    }

    private func openWithdrawSwapScreen() -> SwapScreen {
        launchAndImportHotWallet(expressApiType: .mock, scenarios: [
            ScenarioConfig(name: "bitcoin_utxo", initialState: "Started"),
            ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
            ScenarioConfig(name: "exchange_status_provider", initialState: "Changelly"),
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
            ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty"),
        ])
        .openTangemPay()
        .waitForScreen()
        .verifyBalanceContains("$10.00")
        .tapWithdraw()
        .waitForScreen()
        .tapGotIt()
        .validateSwapScreenDisplayed()
    }

    private func exchangeSentRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Self.exchangeSentEndpointPattern)
    }
}
