//
//  SwapYieldModeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class SwapYieldModeUITests: BaseTestCase {
    private lazy var transactionJournal = EthereumTransactionJournal(wireMockClient: wireMockClient)

    func testSwapYieldModeTokenWithoutApprove() {
        setAllureId(11521)
        launchYieldModeSwap()

        let swapScreen = openSwap(from: importHotWallet())
            .tapProviderBlock()
            .waitForDisplay()
            .assertProviderAvailable(name: Constants.Provider.cex)
            .assertProviderAvailable(name: Constants.Provider.dex)
            .waitForProviderQuote(name: Constants.Provider.dex, containing: Constants.Token.receiveSymbol)
            .assertNoApproveSettingsButtons()
            .selectProviderAndWaitForClose(name: Constants.Provider.dex)
            .verifyProviderName(contains: Constants.Provider.dex)
            .assertFeeAmountContainsFiat()

        let previousTransactions = transactionJournal.sentRawTransactions()

        confirmSwap(swapScreen) { transactionJournal.sentRawTransactions().count == previousTransactions.count }

        XCTContext.runActivity(named: "Verify the swap was sent through the yield module without a separate approve") { _ in
            let newTransactions = transactionJournal.collectNewRawTransactions(after: previousTransactions, expectedCount: 1)
            XCTAssertEqual(newTransactions.count, 1, "Only the swap transaction should be sent")
            XCTAssertEqual(
                newTransactions.map(EthereumTransactionJournal.destination(of:)),
                [Constants.yieldModuleAddress],
                "Swap transaction should be sent to the yield module"
            )
            XCTAssertFalse(
                newTransactions.contains(where: EthereumTransactionJournal.isApprove),
                "No approve should be sent for a Yield mode token"
            )
        }
    }

    func testSwapYieldModeTokenWithGaslessFee() {
        setAllureId(11522)
        launchYieldModeSwap(extraScenarios: [
            ScenarioConfig(name: Constants.Scenario.gaslessTokens, initialState: Constants.State.withEthereumUSDC),
            ScenarioConfig(name: Constants.Scenario.ethNetworkBalance, initialState: Constants.State.empty),
        ])

        let mainScreen = importHotWallet()
            .waitForTokenBalance(tokenName: Constants.Token.nativeName, toEqual: Constants.zeroFiatBalance)

        let swapScreen = openSwap(from: mainScreen)
            .tapProviderBlock()
            .waitForDisplay()
            .selectProviderAndWaitForClose(name: Constants.Provider.cex)
            .verifyProviderName(contains: Constants.Provider.cex)
            .waitForFeeCurrencySymbol(Constants.Token.fromSymbol)
            .assertFeeAmountContainsFiat()
            .assertNoInsufficientFundsError()

        let batchSignCount = gaslessBatchSignCount()
        let reportedExchangeCount = reportedChangellyExchangeCount()

        confirmSwap(swapScreen) { gaslessBatchSignCount() == batchSignCount }

        XCTContext.runActivity(named: "Verify the swap fee was paid through gasless and the exchange was reported") { _ in
            XCTAssertGreaterThan(gaslessBatchSignCount(), batchSignCount, "Swap should be signed through the gasless service")
            let isReported = NSPredicate { _, _ in
                self.reportedChangellyExchangeCount() > reportedExchangeCount
            }
            XCTAssertEqual(
                XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: isReported, object: nil)], timeout: .networkRequest),
                .completed,
                "Exchange with transaction id '\(Constants.changellyTransactionId)' should be reported"
            )
        }
    }

    private func launchYieldModeSwap(extraScenarios: [ScenarioConfig] = []) {
        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            yieldApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: Constants.Scenario.networksProviders, initialState: Constants.State.ethereumProviderPair),
                ScenarioConfig(name: Constants.Scenario.userTokens, initialState: Constants.State.yieldUSDCEthereum),
                ScenarioConfig(name: Constants.Scenario.evmTokenBalances, initialState: Constants.State.nonZeroEvmBalances),
                ScenarioConfig(name: Constants.Scenario.yieldSupplyStatus, initialState: Constants.State.approveGranted),
                ScenarioConfig(name: Constants.Scenario.expressAssets, initialState: Constants.State.yieldUSDCEthereumExchangeEnabled),
                ScenarioConfig(name: Constants.Scenario.ethereumPairs, initialState: Constants.State.yieldUSDC),
                ScenarioConfig(name: Constants.Scenario.exchangeQuoteEthereum, initialState: Constants.State.yieldUSDC),
                ScenarioConfig(name: Constants.Scenario.yieldSwap, initialState: Constants.State.enabled),
            ] + extraScenarios
        )
    }

    private func openSwap(from mainScreen: MainScreen) -> SwapScreen {
        XCTContext.runActivity(named: "Open swap from \(Constants.Token.fromSymbol) with Yield mode to \(Constants.Token.receiveSymbol)") { _ in
            let tokenScreen = mainScreen
                .tapToken(Constants.Token.fromName)
                .waitForNonZeroTotalBalance()
            pullToRefresh()

            return tokenScreen
                .waitForYieldEnabledBlock()
                .waitForNonZeroTotalBalance()
                .tapSwapButton()
                .closeStoriesIfNeeded()
                .validateSwapScreenDisplayed()
                .waitFromTokenDisplayed(tokenSymbol: Constants.Token.fromSymbol)
                .chooseReceiveToken(Constants.Token.receiveName)
                .waitToTokenDisplayed(tokenSymbol: Constants.Token.receiveSymbol)
                .enterFromAmount(Constants.inputAmount)
                .waitForFromAmountValue(Constants.inputAmount)
                .assertFeeAmountContainsFiat()
        }
    }

    private func confirmSwap(_ swapScreen: SwapScreen, isNothingSent: () -> Bool) {
        swapScreen
            .confirmSwapUntilFinishOpened(isNothingSent: isNothingSent)
            .assertHeaderTitle(Constants.swapInProgressTitle)
    }

    private func reportedChangellyExchangeCount() -> Int {
        wireMockClient
            .findRequestBodiesSync(method: Constants.Endpoint.post, urlPath: Constants.Endpoint.exchangeSent)
            .filter { $0.contains(Constants.changellyTransactionId) }
            .count
    }

    private func gaslessBatchSignCount() -> Int {
        wireMockClient.requestCountSync(method: Constants.Endpoint.post, urlPathPattern: Constants.Endpoint.gaslessBatchSign)
    }
}

private extension SwapYieldModeUITests {
    enum Constants {
        static let inputAmount = "100"
        static let swapInProgressTitle = "Swap in progress"
        static let zeroFiatBalance = "$0.00"
        static let yieldModuleAddress = "0x" + String(repeating: "1", count: 40)
        static let changellyTransactionId = "yield-usdc-eth-changelly-tx-001"

        enum Token {
            static let fromName = "USDC"
            static let fromSymbol = "USDC"
            static let receiveName = "Ethereum"
            static let receiveSymbol = "ETH"
            static let nativeName = "Ethereum"
        }

        enum Provider {
            static let dex = "1Inch"
            static let cex = "Changelly"
        }

        enum Endpoint {
            static let post = "POST"
            static let gaslessBatchSign = "/gasless/api/v2/transaction/batch-sign"
            static let exchangeSent = "/v1/exchange-sent"
        }

        enum Scenario {
            static let networksProviders = "networks_providers"
            static let userTokens = "user_tokens_api"
            static let evmTokenBalances = "moralis_evm_token_balances_api"
            static let yieldSupplyStatus = "yield_supply_status"
            static let expressAssets = "express_api_assets"
            static let ethereumPairs = "ethereum_pairs"
            static let exchangeQuoteEthereum = "exchange_quote_ethereum"
            static let yieldSwap = "yield_swap"
            static let gaslessTokens = "gasless_tokens"
            static let ethNetworkBalance = "eth_network_balance"
        }

        enum State {
            static let ethereumProviderPair = "EthereumProviderPair"
            static let yieldUSDCEthereum = "YieldUSDCEthereum"
            static let nonZeroEvmBalances = "NonZeroEvmBalances"
            static let approveGranted = "ApproveGranted"
            static let yieldUSDCEthereumExchangeEnabled = "YieldUSDCEthereumExchangeEnabled"
            static let yieldUSDC = "YieldUSDC"
            static let enabled = "Enabled"
            static let withEthereumUSDC = "WithEthereumUSDC"
            static let empty = "Empty"
        }
    }
}
