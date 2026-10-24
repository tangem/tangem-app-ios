//
//  TangemPayCrossWalletSwapUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayCrossWalletSwapUITests: BaseTestCase {
    func testSwapFromFirstWalletTokenToSecondWalletPaymentAccount() {
        setAllureId(9680)
        wireMockClient.resetRequestJournalSync()

        launchAndImportHotWallet(expressApiType: .mock, scenarios: Constants.Scenarios.deposit)
            .addNewWallet(name: .wallet2)
            .waitForTokenBalanceLoaded(tokenName: Constants.Token.tether)
            .openVisibleTangemPay(subtitle: Constants.cardSubtitle)
            .waitForScreen()
            .verifyBalanceContains(Constants.Balance.initial)
            .tapAddFunds()
            .waitForScreen()
            .tapSwap()
            .validateSwapScreenDisplayed()
            .tapFromTokenSelector()
            .selectWallet(Constants.Wallet.hot)
            .selectToken(Constants.Token.tether, inAccount: Localization.accountMainAccountTitle)
            .waitFromTokenDisplayed(tokenSymbol: Constants.Token.usdtSymbol)
            .waitForFromBalanceDisplayed()
            .enterFromAmount(Constants.Amount.deposit)
            .confirmSwap()

        SendFinishScreen(app)
            .waitForDisplay()
            .assertSwapSourceAmount(containsLabels: [
                [Localization.accountMainAccountTitle],
                [Constants.Amount.deposit, Constants.Token.usdtSymbol],
            ])
            .assertSwapDestinationAmount(containsLabels: [
                [Localization.tangempayPaymentAccount],
                [Constants.Token.usdc],
            ])
            .tapCloseButton()

        XCTContext.runActivity(named: "Verify the swap is paid from the first wallet's token") { _ in
            let fromAddresses = exchangeDataQueryValues(Constants.Query.fromAddress)
            XCTAssertFalse(fromAddresses.isEmpty, "The swap should request exchange data")
            XCTAssertTrue(
                fromAddresses.allSatisfy { $0 == Constants.hotWalletEthereumAddress },
                "The swap should be paid from the first wallet's Tether. Actual source addresses: \(fromAddresses)"
            )
        }

        completePaymentAccountTransfer(state: Constants.State.afterDeposit)
        verifyPaymentAccountBalance(Constants.Balance.afterDeposit)
            .tapBack()
        let tetherBalance = showPreviousWallet()
            .waitForTokenBalanceLoaded(tokenName: Constants.Token.tether)
            .getTokenBalanceNumeric(tokenName: Constants.Token.tether)

        completeOnChainTransfer(state: Constants.State.afterPayDeposit)
        MainScreen(app).scrollToTop()
        pullToRefresh()
        MainScreen(app).waitForTokenBalance(tokenName: Constants.Token.tether, to: .decrease, from: tetherBalance)
    }

    func testSwapFromPaymentAccountToOtherWalletTokenViaWithdraw() {
        setAllureId(9683)
        wireMockClient.resetRequestJournalSync()

        let mainScreen = launchWithSecondWallet()
        let tetherBalance = mainScreen.getTokenBalanceNumeric(tokenName: Constants.Token.tether)

        showPreviousWallet()
            .openVisibleTangemPay(subtitle: Constants.cardSubtitle)
            .waitForScreen()
            .verifyBalanceContains(Constants.Balance.initial)
            .tapWithdrawOpeningHub()
            .tapWithinPortfolio()
            .tapToTokenSelector()
            .selectWallet(Constants.Wallet.card)
            .selectToken(Constants.Token.tether, inAccount: Localization.accountMainAccountTitle)
            .waitToTokenDisplayed(tokenSymbol: Constants.Token.usdtSymbol)
            .enterFromAmount(Constants.Amount.withdraw)
            .confirmSwap()

        verifyWithdrawFinishScreen()
        completeTransfer(payBalanceState: Constants.State.afterWithdraw, tetherBalanceState: Constants.State.afterPayWithdraw)
        verifyPaymentAccountBalance(Constants.Balance.afterWithdraw)
            .tapBack()
        showNextWallet()
        pullToRefresh()
        MainScreen(app).waitForTokenBalance(tokenName: Constants.Token.tether, to: .increase, from: tetherBalance)
    }

    func testSwapFromPaymentAccountToOtherWalletTokenFromMainToken() {
        setAllureId(12128)
        wireMockClient.resetRequestJournalSync()

        let mainScreen = launchWithSecondWallet()
        let tetherBalance = mainScreen.getTokenBalanceNumeric(tokenName: Constants.Token.tether)

        mainScreen
            .tapToken(Constants.Token.tether)
            .waitForNonZeroTotalBalance()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapFromTokenSelector()
            .selectWallet(Constants.Wallet.hot)
            .selectToken(Constants.Token.usdc, inAccount: Localization.tangempayPaymentAccount)
            .tapToTokenSelector()
            .selectWallet(Constants.Wallet.card)
            .selectToken(Constants.Token.tether, inAccount: Localization.accountMainAccountTitle)
            .waitToTokenDisplayed(tokenSymbol: Constants.Token.usdtSymbol)
            .enterFromAmount(Constants.Amount.withdraw)
            .confirmSwap()

        verifyWithdrawFinishScreen()
        completeTransfer(payBalanceState: Constants.State.afterWithdraw, tetherBalanceState: Constants.State.afterPayWithdraw)

        let walletScreen = TokenScreen(app).goBackToMain()
        pullToRefresh()
        walletScreen.waitForTokenBalance(tokenName: Constants.Token.tether, to: .increase, from: tetherBalance)

        showPreviousWallet()
            .openVisibleTangemPay(subtitle: Constants.cardSubtitle)
            .waitForScreen()
            .verifyBalanceContains(Constants.Balance.afterWithdraw)
    }

    @discardableResult
    private func showPreviousWallet() -> MainScreen {
        pullToRefresh()
        return MainScreen(app).swipeWalletRight()
    }

    @discardableResult
    private func showNextWallet() -> MainScreen {
        pullToRefresh()
        return MainScreen(app).swipeWalletLeft()
    }

    private func launchWithSecondWallet() -> MainScreen {
        launchAndImportHotWalletWithRealPayAuthorization(expressApiType: .mock, scenarios: Constants.Scenarios.withdraw)
            .addNewWallet(name: .wallet2)
            .waitForTokenBalanceLoaded(tokenName: Constants.Token.tether)
    }

    private func verifyWithdrawFinishScreen() {
        SendFinishScreen(app)
            .waitForDisplay()
            .assertSwapSourceAmount(containsLabels: [
                [Localization.tangempayPaymentAccount],
                [Constants.Amount.withdraw, Constants.Token.usdc],
            ])
            .assertSwapDestinationAmount(containsLabels: [
                [Localization.accountMainAccountTitle],
                [Constants.Token.usdtSymbol],
            ])
            .tapCloseButton()

        XCTContext.runActivity(named: "Verify the swap pays out to the second wallet's token") { _ in
            let toAddresses = exchangeDataQueryValues(Constants.Query.toAddress)
            XCTAssertFalse(toAddresses.isEmpty, "The swap should request exchange data")
            XCTAssertTrue(
                toAddresses.allSatisfy { $0 == Constants.cardWalletEthereumAddress },
                "The swap should pay out to the second wallet's Tether. Actual payout addresses: \(toAddresses)"
            )
        }
    }

    private func completeTransfer(payBalanceState: String, tetherBalanceState: String) {
        completePaymentAccountTransfer(state: payBalanceState)
        completeOnChainTransfer(state: tetherBalanceState)
    }

    private func completePaymentAccountTransfer(state: String) {
        XCTContext.runActivity(named: "Complete the transfer on the Payment account backend") { _ in
            wireMockClient.setScenarioStateSync(Constants.Scenario.payBalance, state: state)
        }
    }

    private func completeOnChainTransfer(state: String) {
        XCTContext.runActivity(named: "Complete the transfer on chain") { _ in
            wireMockClient.setScenarioStateSync(Constants.Scenario.tetherBalance, state: state)
        }
    }

    private func exchangeDataQueryValues(_ name: String) -> [String] {
        wireMockClient.findRequestURLsSync(method: "GET", urlPath: Constants.Endpoint.exchangeData)
            .compactMap { URLComponents(string: $0)?.queryItems?.first { $0.name == name }?.value?.lowercased() }
    }

    private func verifyPaymentAccountBalance(_ balance: String) -> TangemPayMainScreen {
        TangemPayMainScreen(app).waitForScreen()
        pullToRefresh()
        return TangemPayMainScreen(app).verifyBalanceContains(balance)
    }
}

private extension TangemPayCrossWalletSwapUITests {
    enum Constants {
        static let cardSubtitle = "*4242"
        static let hotWalletEthereumAddress = "0x3369554b994908d249d307b105f8e5e3115615c2"
        static let cardWalletEthereumAddress = "0xe34979ea46a0bb49f0e483f163c79be02101cd1b"

        enum Wallet {
            static let hot = "Wallet"
            static let card = "Wallet 2"
        }

        enum Token {
            static let tether = "Tether"
            static let usdtSymbol = "USDT"
            static let usdc = "USDC"
        }

        enum Amount {
            static let deposit = "100"
            static let withdraw = "5"
        }

        enum Balance {
            static let initial = "$10.00"
            static let afterDeposit = "$110.00"
            static let afterWithdraw = "$5.00"
        }

        enum Query {
            static let fromAddress = "fromAddress"
            static let toAddress = "toAddress"
        }

        enum Endpoint {
            static let exchangeData = "/v1/exchange-data"
        }

        enum Scenario {
            static let payBalance = "tangem_pay_balance_update"
            static let tetherBalance = "ethereum_usdt_balance"
        }

        enum State {
            static let afterDeposit = "AfterDeposit"
            static let afterWithdraw = "AfterWithdraw"
            static let afterPayDeposit = "AfterPayDeposit"
            static let afterPayWithdraw = "AfterPayWithdraw"
        }

        enum Scenarios {
            static let deposit = common + [
                ScenarioConfig(name: Scenario.payBalance, initialState: "InitialBalance"),
            ]

            static let withdraw = common + [
                ScenarioConfig(name: Scenario.payBalance, initialState: "InitialBalanceMultinetwork"),
                ScenarioConfig(name: "tangem_pay_eligibility_channels", initialState: "BankOfframp"),
            ]

            private static let common = [
                ScenarioConfig(name: "user_tokens_api", initialState: "USDT"),
                ScenarioConfig(name: "eth_call_api", initialState: "Started"),
                ScenarioConfig(name: "eth_network_balance", initialState: "Started"),
                ScenarioConfig(name: "express_api_assets", initialState: "PayUsdtEthereum"),
                ScenarioConfig(name: "exchange_status_provider", initialState: "Changelly"),
                ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty"),
            ]
        }
    }
}
