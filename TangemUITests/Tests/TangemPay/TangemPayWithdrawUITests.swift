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
    }

    func testWithdrawSourceSelector_ListsPaymentAccountTokensAndHidesZeroBalance() {
        setAllureId(11385)

        openMultiNetworkWithdrawSwapScreen()
            .tapFromTokenSelector()
            .verifyTokenCount(2)
            .waitForTokenDisplayed("USDT")
            .selectBalanceFilter(.all)
            .verifyTokenCount(3)
    }

    func testWithdraw_FromSelectedPaymentAccountToken_SendsTargetedRequest() {
        setAllureId(11386)

        wireMockClient.resetRequestJournalSync()

        openMultiNetworkWithdrawSwapScreen()
            .chooseSourceToken("USDT")
            .chooseTokenFromEmptySelector("Bitcoin")
            .enterFromAmount("5")
            .confirmSwap()

        SendFinishScreen(app)
            .waitForDisplay()
            .tapCloseButton()

        XCTContext.runActivity(named: "Verify the withdrawal was addressed to USDT on BNB Smart Chain") { _ in
            let body = onlyWithdrawRequestBody()
            XCTAssertEqual(body["chain_id"] as? Int, Constants.bscChainId, "Withdrawal should name the BNB Smart Chain id")
            XCTAssertEqual(
                (body["token_contract_address"] as? String)?.lowercased(),
                Constants.usdtBscContractAddress,
                "Withdrawal should name the selected USDT contract"
            )
        }

        wireMockClient.setScenarioStateSync("tangem_pay_balance_update", state: "MultiNetworkStatusesAfterWithdraw")

        TangemPayMainScreen(app).waitForScreen()
        pullToRefresh()
        TangemPayMainScreen(app).verifyBalanceContains("$12.00")
    }

    private func openWithdrawSwapScreen() -> SwapScreen {
        launchAndImportHotWallet(expressApiType: .mock, scenarios: [
            ScenarioConfig(name: "bitcoin_utxo", initialState: "Started"),
            ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
            ScenarioConfig(name: "exchange_status_provider", initialState: "Changelly"),
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalanceMultinetwork"),
            ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty"),
        ])
        .openTangemPay()
        .waitForScreen()
        .verifyBalanceContains("$10.00")
        .tapWithdraw()
        .validateSwapScreenDisplayed()
    }

    private func openMultiNetworkWithdrawSwapScreen() -> SwapScreen {
        launchAndImportHotWallet(expressApiType: .mock, scenarios: [
            ScenarioConfig(name: "bitcoin_utxo", initialState: "Started"),
            ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabledMultinetwork"),
            ScenarioConfig(name: "exchange_status_provider", initialState: "Changelly"),
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "MultiNetworkStatuses"),
            ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty"),
        ])
        .openTangemPay()
        .waitForScreen()
        .verifyBalanceContains("$17.00")
        .tapWithdraw()
        .validateSwapScreenDisplayed()
    }

    private func exchangeSentRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Constants.Endpoint.exchangeSentPattern)
    }

    private func onlyWithdrawRequestBody() -> [String: Any] {
        let bodies = wireMockClient.findRequestBodiesSync(method: "POST", urlPath: Constants.Endpoint.withdraw)

        guard bodies.count == 1,
              let data = bodies[0].data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            XCTFail("Exactly one withdrawal request with a JSON body should be journalled, but found \(bodies.count)")
            return [:]
        }

        return json
    }
}

private extension TangemPayWithdrawUITests {
    enum Constants {
        static let usdtBscContractAddress = "0x55d398326f99059ff775485246999027b3197955"
        static let bscChainId = 56

        enum Endpoint {
            /// CEX withdraw submits via Express, not /customer/card/withdraw; assert single swap submission on this endpoint.
            static let exchangeSentPattern = "/v1/exchange-sent"
            static let withdraw = "/bff-v2/v1/customer/card/withdraw"
        }
    }
}
