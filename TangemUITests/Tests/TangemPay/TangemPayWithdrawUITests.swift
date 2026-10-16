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
            .verifyTransactionRowVisible(label: Localization.tangemPayWithdrawal)
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
            .verifyTransactionRowVisible(label: Localization.tangemPayWithdrawal)
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

    func testWithdrawEnabled_WhenOnlyOneNonPolygonNetworkIsWithdrawable() {
        setAllureId(11645)

        for (network, balanceState) in Constants.State.withdrawableOnlyOnNetwork {
            XCTContext.runActivity(named: "Verify Withdraw with the withdrawable balance only on \(network.displayName)") { _ in
                let paymentAccount = launchAndImportHotWallet(expressApiType: .mock, scenarios: [
                    ScenarioConfig(name: Constants.Scenario.balance, initialState: balanceState),
                    ScenarioConfig(name: Constants.Scenario.expressAssets, initialState: Constants.State.payWithdrawAllNetworks),
                    ScenarioConfig(name: Constants.Scenario.history, initialState: Constants.State.emptyHistory),
                    ScenarioConfig(name: Constants.Scenario.eligibilityChannels, initialState: Constants.State.withoutBankOfframp),
                ])
                .openTangemPay()
                .waitForScreen()

                paymentAccount
                    .verifyBalanceContains(Constants.singleNetworkBalance)
                    .verifyWithdrawEnabled()
                    .tapWithdraw()
                    .validateSwapScreenDisplayed()
                    .waitFromTokenDisplayed(tokenSymbol: Constants.usdcSymbol)
                    .tapFromTokenSelector()
                    .verifyTokenCount(Constants.withdrawableTokenCount)
                    .selectBalanceFilter(.all)
                    .verifyTokenCount(Constants.enabledNetworkTokenCount)
            }
        }
    }

    func testWithdraw_WithdrawDataFails_ShowsError() {
        setAllureId(9605)

        confirmBitcoinWithdraw(withdrawState: Constants.State.withdrawDataError)
            .waitForErrorAlert()

        XCTContext.runActivity(named: "Verify the withdrawal stopped before submitting") { _ in
            XCTAssertEqual(withdrawDataRequestCount(), 1, "Withdrawal data should be requested once")
            XCTAssertEqual(withdrawRequestCount(), 0, "Withdrawal should not be submitted without signing data")
            XCTAssertEqual(exchangeSentRequestCount(), 0, "Failed withdrawal should not be reported to Express")
        }
    }

    func testWithdraw_WithdrawFailsAfterSigning_ShowsError() {
        setAllureId(9606)

        confirmBitcoinWithdraw(withdrawState: Constants.State.withdrawError)
            .waitForErrorAlert()

        XCTContext.runActivity(named: "Verify the signed withdrawal was submitted and failed") { _ in
            XCTAssertEqual(withdrawDataRequestCount(), 1, "Withdrawal data should be requested once")
            XCTAssertEqual(withdrawRequestCount(), 1, "Signed withdrawal should be submitted once")
            XCTAssertEqual(orderRequestCount(), 0, "Failed withdrawal should not poll the order")
            XCTAssertEqual(exchangeSentRequestCount(), 0, "Failed withdrawal should not be reported to Express")
        }
    }

    func testWithdraw_StaysOnSwapUntilTransactionHashArrives() {
        setAllureId(9660)

        confirmBitcoinWithdraw(withdrawState: Constants.State.orderPendingFirstPoll)
            .verifyFinishScreenNotOpened(within: Constants.pendingOrderObservationTime)

        XCTContext.runActivity(named: "Verify the order is being polled while the Swap screen stays open") { _ in
            XCTAssertGreaterThan(orderRequestCount(), 0, "The order should already be polled while the transaction hash is missing")
        }

        SwapScreen(app).validateSwapScreenDisplayed()
        SendFinishScreen(app).waitForDisplay()

        XCTContext.runActivity(named: "Verify the order was polled until the transaction hash arrived") { _ in
            XCTAssertEqual(
                orderRequestCount(),
                Constants.pollsUntilTransactionHash,
                "The order should be polled again after each response without a transaction hash"
            )
        }
    }

    func testWithdraw_TransactionHashNotReceivedAfterMaxPollAttempts_ShowsError() {
        setAllureId(9659)

        confirmBitcoinWithdraw(withdrawState: Constants.State.orderWithoutHash)
            .waitForErrorAlert()

        XCTContext.runActivity(named: "Verify the order was polled the maximum number of times") { _ in
            XCTAssertEqual(orderRequestCount(), Constants.maxOrderPollAttempts, "The order should be polled exactly \(Constants.maxOrderPollAttempts) times")
            XCTAssertEqual(exchangeSentRequestCount(), 0, "Withdrawal without a transaction hash should not be reported to Express")
        }
    }

    private func confirmBitcoinWithdraw(withdrawState: String) -> SwapScreen {
        let swapScreen = openWithdrawSwapScreen(extraScenarios: [
            ScenarioConfig(name: Constants.Scenario.withdraw, initialState: withdrawState),
        ])
        .chooseTokenFromEmptySelector(Constants.bitcoinName)
        .enterFromAmount(Constants.withdrawAmount)

        wireMockClient.resetRequestJournalSync()
        swapScreen.confirmSwap()
        return swapScreen
    }

    private func openWithdrawSwapScreen(extraScenarios: [ScenarioConfig] = []) -> SwapScreen {
        launchAndImportHotWalletWithRealPayAuthorization(expressApiType: .mock, scenarios: [
            ScenarioConfig(name: "bitcoin_utxo", initialState: "Started"),
            ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
            ScenarioConfig(name: "exchange_status_provider", initialState: "Changelly"),
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalanceMultinetwork"),
            ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty"),
            // Without BANK_OFFRAMP among the eligible channels the Withdraw button keeps opening the swap flow.
            ScenarioConfig(name: Constants.Scenario.eligibilityChannels, initialState: Constants.State.withoutBankOfframp),
        ] + extraScenarios)
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains("$10.00")
            .tapWithdraw()
            .validateSwapScreenDisplayed()
    }

    private func openMultiNetworkWithdrawSwapScreen() -> SwapScreen {
        launchAndImportHotWalletWithRealPayAuthorization(expressApiType: .mock, scenarios: [
            ScenarioConfig(name: "bitcoin_utxo", initialState: "Started"),
            ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabledMultinetwork"),
            ScenarioConfig(name: "exchange_status_provider", initialState: "Changelly"),
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "MultiNetworkStatuses"),
            ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty"),
            // Without BANK_OFFRAMP among the eligible channels the Withdraw button keeps opening the swap flow.
            ScenarioConfig(name: Constants.Scenario.eligibilityChannels, initialState: Constants.State.withoutBankOfframp),
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

    private func withdrawDataRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Constants.Endpoint.withdrawData)
    }

    private func withdrawRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Constants.Endpoint.withdraw)
    }

    private func orderRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "GET", urlPathPattern: Constants.Endpoint.withdrawOrder)
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
        static let usdcSymbol = "USDC"
        static let singleNetworkBalance = "$10.00"
        static let withdrawableTokenCount = 1
        static let enabledNetworkTokenCount = 2
        static let bitcoinName = "Bitcoin"
        static let withdrawAmount = "5"
        static let pollsUntilTransactionHash = 4
        static let pendingOrderObservationTime: TimeInterval = 7
        static let maxOrderPollAttempts = 10

        enum Scenario {
            static let eligibilityChannels = "tangem_pay_eligibility_channels"
            static let balance = "tangem_pay_balance_update"
            static let history = "tangem_pay_transaction_history"
            static let expressAssets = "express_api_assets"
            static let withdraw = "tangem_pay_withdraw"
        }

        enum State {
            static let withoutBankOfframp = "Started"
            static let emptyHistory = "InitialEmpty"
            static let payWithdrawAllNetworks = "PayWithdrawAllNetworks"
            static let withdrawDataError = "WithdrawDataError"
            static let withdrawError = "WithdrawError"
            static let orderPendingFirstPoll = "OrderPendingFirstPoll"
            static let orderWithoutHash = "OrderWithoutHash"
            static let withdrawableOnlyOnNetwork: [(TangemPayNetwork, String)] = [
                (.bsc, "WithdrawableOnlyOnBsc"),
                (.base, "WithdrawableOnlyOnBase"),
                (.arbitrum, "WithdrawableOnlyOnArbitrum"),
            ]
        }

        enum Endpoint {
            /// CEX withdraw submits via Express, not /customer/card/withdraw; assert single swap submission on this endpoint.
            static let exchangeSentPattern = "/v1/exchange-sent"
            static let withdraw = "/bff-v2/v1/customer/card/withdraw"
            static let withdrawData = "/bff-v2/v1/customer/card/withdraw/data"
            static let withdrawOrder = "/bff-v2/v1/order/mock-tangempay-withdraw-order-001"
        }
    }
}
