//
//  TangemPayHiddenBalancesUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayHiddenBalancesUITests: BaseTestCase {
    func testPaymentAccountBalance_UsesMainScreenMask() {
        setAllureId(12742)

        launchWithHiddenBalances(scenarios: [
            ScenarioConfig(name: Constants.Scenario.balance, initialState: Constants.State.initialBalance),
        ])
        .verifyTotalBalanceRemains(Constants.mask)
        .verifyTangemPayTileBalanceContains(Constants.mask)
        .openTangemPay()
        .waitForScreen()
        .verifyBalance(Constants.mask)
    }

    func testTransactionHistory_MasksAmountAndCashbackInListAndDetails() {
        setAllureId(12743)

        launchWithHiddenBalances(scenarios: [
            ScenarioConfig(name: Constants.Scenario.cashback, initialState: Constants.State.positiveCashback),
            ScenarioConfig(name: Constants.Scenario.history, initialState: Constants.State.cashbackTransactions),
        ])
        .openTangemPay()
        .waitForScreen()
        .verifyTransactionCashback(name: Constants.Transaction.name, cashback: Constants.mask)
        .verifyTransactionRow(name: Constants.Transaction.name, amount: Constants.mask, category: Constants.Transaction.category)
        .tapTransaction(name: Constants.Transaction.name)
        .waitForScreen()
        .verifyAmount(Constants.mask)
        .verifyCashback(Constants.mask)
    }

    func testCashbackWidget_MasksAmount() {
        setAllureId(12745)

        launchWithHiddenBalances(scenarios: [
            ScenarioConfig(name: Constants.Scenario.cashback, initialState: Constants.State.positiveCashback),
        ])
        .openTangemPay()
        .waitForScreen()
        .verifyCashbackWidget(amount: Constants.mask, month: currentMonthName())
    }

    func testCashbackPage_MasksHeaderAndEarningsBars() {
        setAllureId(12751)

        launchWithHiddenBalances(scenarios: [
            ScenarioConfig(name: Constants.Scenario.cashback, initialState: Constants.State.positiveCashback),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCashbackWidget()
        .verifyEarnedHeader(amount: Constants.mask, month: currentMonthName())
        .verifyChartTotal(Constants.mask)
        .verifyChartValues(Constants.mask, count: Constants.earningMonthsCount)
    }

    func testAddFundsFromTangemWallet_MasksPaymentAccountBalance() {
        setAllureId(12746)

        launchWithHiddenBalances(expressApiType: .mock, scenarios: [
            ScenarioConfig(name: Constants.Scenario.bitcoin, initialState: Constants.State.bitcoinBalance),
            ScenarioConfig(name: Constants.Scenario.expressAssets, initialState: Constants.State.bitcoinExchangeEnabled),
            ScenarioConfig(name: Constants.Scenario.balance, initialState: Constants.State.initialBalance),
            ScenarioConfig(name: Constants.Scenario.history, initialState: Constants.State.emptyHistory),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapAddFunds()
        .waitForScreen()
        .tapSwap()
        .validateSwapScreenDisplayed()
        .verifyReceiveBalance(contains: Constants.mask)
    }

    private func launchWithHiddenBalances(expressApiType: ExpressAPI? = nil, scenarios: [ScenarioConfig] = []) -> MainScreen {
        launchAndImportHotWallet(
            expressApiType: expressApiType,
            scenarios: scenarios,
            extraLaunchArguments: [Constants.hideBalancesArgument]
        )
    }

    private func currentMonthName() -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let formatter = DateFormatter()
        formatter.locale = UITestLocale.locale
        return formatter.standaloneMonthSymbols[calendar.component(.month, from: Date()) - 1]
    }
}

private extension TangemPayHiddenBalancesUITests {
    enum Constants {
        static let hideBalancesArgument = "-uitest-hide-balances"
        static let mask = "\u{2217}\u{2217}\u{2217}"
        static let earningMonthsCount = 4

        enum Scenario {
            static let cashback = "tangem_pay_cashback"
            static let history = "tangem_pay_transaction_history"
            static let balance = "tangem_pay_balance_update"
            static let bitcoin = "bitcoin_utxo"
            static let expressAssets = "express_api_assets"
        }

        enum State {
            static let positiveCashback = "Positive"
            static let cashbackTransactions = "CashbackTransactions"
            static let initialBalance = "InitialBalance"
            static let emptyHistory = "InitialEmpty"
            static let bitcoinBalance = "Balance"
            static let bitcoinExchangeEnabled = "BitcoinExchangeEnabled"
        }

        enum Transaction {
            static let name = "Cashback Coffee"
            static let category = "Shopping"
        }
    }
}
