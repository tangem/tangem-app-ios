//
//  TangemPayCashbackUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayCashbackUITests: BaseTestCase {
    func testNonEuWidget_PositiveAmount_ShowsAmountAndNoMenuItem() {
        setAllureId(10934)

        launchWithCashback(Constants.State.positive)
            .verifyCashbackWidget(amount: Constants.Amount.positive, month: currentMonthName())
            .openMoreActionsMenu()
            .verifyCashbackMenuItemHidden()
    }

    func testNonEuWidget_ZeroAmount_ShowsZeroForCurrentMonth() {
        setAllureId(10935)

        launchWithCashback(Constants.State.empty)
            .verifyCashbackWidget(amount: Constants.Amount.zero, month: currentMonthName())
    }

    func testNonEuWidget_NegativeAmount_ShowsAmountWithMinus() {
        setAllureId(10936)

        launchWithCashback(Constants.State.refund)
            .verifyCashbackWidget(amount: Constants.Amount.refund, month: currentMonthName())
    }

    func testEuLayout_ShowsCashbackInMenuInsteadOfWidget() {
        setAllureId(10938)

        launchWithCashback(Constants.State.altBlock)
            .waitForBalanceLoaded()
            .verifyCashbackWidgetHidden()
            .openMoreActionsMenu()
            .verifyCashbackMenuItem(month: currentMonthName())
    }

    func testCashbackScreen_NoCashback_ShowsEmptyState() {
        setAllureId(10944)

        launchWithCashback(Constants.State.empty)
            .verifyCashbackWidget(amount: Constants.Amount.zero, month: currentMonthName())
            .tapCashbackWidget()
            .verifyEmptyHeader()
            .verifyAccrualsCard()
            .verifyRateCard(rate: Constants.Promotion.rate, plan: Constants.Promotion.plan)
            .verifyChartTotal(Constants.Amount.zero)
            .verifyChartMonths(chartMonths())
            .verifyAdditionalCashbackSection()
    }

    func testCashbackScreen_CurrentMonthAccruals_ShowsEarnedAmountAndChart() {
        setAllureId(10946)

        let months = chartMonths()

        launchWithCashback(Constants.State.positive)
            .verifyCashbackWidget(amount: Constants.Amount.positive, month: currentMonthName())
            .tapCashbackWidget()
            .verifyEarnedHeader(amount: Constants.Amount.positive, month: currentMonthName())
            .verifyPayoutWindow(nextMonthPayoutWindow())
            .verifyAccrualsCard()
            .verifyRateCard(rate: Constants.Promotion.rate, plan: Constants.Promotion.plan)
            .verifyChartTotal(Constants.Amount.positiveTotal)
            .verifyChartMonths(months)
            .verifyChartValue(Constants.Amount.fourMonthsAgo, month: months[0])
            .verifyChartValue(Constants.Amount.previousMonth, month: months[3])
            .verifyChartValue(Constants.Amount.positive, month: months[4])
    }

    func testCashbackScreen_Refund_ShowsNegativeAmountAndRefundBanner() {
        setAllureId(10947)

        let months = chartMonths()

        launchWithCashback(Constants.State.refund)
            .tapCashbackWidget()
            .verifyEarnedHeader(amount: Constants.Amount.refund, month: currentMonthName())
            .verifyPayoutWindowHidden()
            .verifyRefundBanner()
            .verifyChartTotal(Constants.Amount.refund)
            .verifyChartValue(Constants.Amount.refund, month: months[4])
    }

    func testCashbackScreen_HistoryRequestFails_ShowsFailureAndRecoversOnReload() {
        setAllureId(10948)

        let cashback = launchWithCashback(Constants.State.historyFailed)
            .tapCashbackWidget()
            .verifyFailedState()

        wireMockClient.setScenarioStateSync(Constants.Scenario.cashback, state: Constants.State.positive)

        cashback
            .tapReload()
            .verifyEarnedHeader(amount: Constants.Amount.positive, month: currentMonthName())
    }

    func testFraudStatus_ShowsDeactivationBannerUntilGotIt() {
        setAllureId(10949)

        launchWithCashback(Constants.State.fraud)
            .verifyCashbackDeactivatedBanner()
            .verifyCashbackWidgetHidden()
            .tapCashbackDeactivatedGotIt()
            .waitForCashbackDeactivatedBannerHidden()
            .openMoreActionsMenu()
            .verifyCashbackMenuItemHidden()
    }

    func testCashbackScreen_PayoutInProgress_ShowsPayoutBanner() {
        setAllureId(10953)

        let payout = previousPayout()

        launchWithCashback(Constants.State.payout)
            .tapCashbackWidget()
            .verifyEarnedHeader(amount: Constants.Amount.payout, month: currentMonthName())
            .verifyPayoutWindow(nextMonthPayoutWindow())
            .verifyDepositBanner(amount: Constants.Amount.previousPayout, month: payout.month, payoutDate: payout.date)
    }

    func testTransactionHistory_ShowsCashbackWithSignPerTransaction() {
        setAllureId(11604)

        launchWithCashback(Constants.State.positive, history: Constants.State.cashbackTransactions)
            .verifyTransactionCashback(name: Constants.Transaction.spend, cashback: Constants.Transaction.spendCashback)
            .verifyTransactionCashback(name: Constants.Transaction.refund, cashback: Constants.Transaction.refundCashback)
    }

    private func launchWithCashback(_ state: String, history: String? = nil) -> TangemPayMainScreen {
        var scenarios = [ScenarioConfig(name: Constants.Scenario.cashback, initialState: state)]

        if let history {
            scenarios.append(ScenarioConfig(name: Constants.Scenario.history, initialState: history))
        }

        return launchAndImportHotWallet(scenarios: scenarios)
            .openTangemPay()
            .waitForScreen()
    }

    private func currentMonthName() -> String {
        monthName(of: Date(), symbols: Constants.Formatting.monthFormatter.standaloneMonthSymbols)
    }

    private func chartMonths() -> [String] {
        (-4 ... 0).map { offset in
            let date = Constants.Formatting.calendar.date(byAdding: .month, value: offset, to: Date()) ?? Date()
            return monthName(of: date, symbols: Constants.Formatting.monthFormatter.shortStandaloneMonthSymbols)
        }
    }

    private func nextMonthPayoutWindow() -> String {
        let calendar = Constants.Formatting.calendar
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        var components = calendar.dateComponents([.year, .month], from: nextMonth)
        components.day = 2
        let start = calendar.date(from: components) ?? nextMonth
        components.day = 5
        let end = calendar.date(from: components) ?? nextMonth
        return Constants.Formatting.payoutWindowFormatter.string(from: start, to: end)
    }

    private func previousPayout() -> (month: String, date: String) {
        let calendar = Constants.Formatting.calendar
        let endDate = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: Date())) ?? Date()
        let earnedMonth = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        return (
            monthName(of: earnedMonth, symbols: Constants.Formatting.monthFormatter.standaloneMonthSymbols),
            Constants.Formatting.payoutDateFormatter.string(from: endDate)
        )
    }

    private func monthName(of date: Date, symbols: [String]) -> String {
        symbols[Constants.Formatting.calendar.component(.month, from: date) - 1]
    }
}

private extension TangemPayCashbackUITests {
    enum Constants {
        enum Scenario {
            static let cashback = "tangem_pay_cashback"
            static let history = "tangem_pay_transaction_history"
        }

        enum State {
            static let positive = "Positive"
            static let empty = "Empty"
            static let refund = "Refund"
            static let altBlock = "AltBlock"
            static let fraud = "Fraud"
            static let payout = "Payout"
            static let historyFailed = "HistoryFailed"
            static let cashbackTransactions = "CashbackTransactions"
        }

        enum Amount {
            static let positive = "$32.15"
            static let positiveTotal = "$153"
            static let fourMonthsAgo = "$10.40"
            static let previousMonth = "$85.35"
            static let zero = "$0"
            static let refund = "-$3.20"
            static let payout = "$5.40"
            static let previousPayout = "$12.80"
        }

        enum Transaction {
            static let spend = "Cashback Coffee"
            static let spendCashback = "+$0.12"
            static let refund = "Cashback Books"
            static let refundCashback = "-$0.08"
        }

        enum Promotion {
            static let rate = "1"
            static let plan = "Basic"
        }

        enum Formatting {
            static let locale = Locale(identifier: "en_US")
            static let timeZone = TimeZone.gmt

            static let calendar: Calendar = {
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = timeZone
                return calendar
            }()

            static let monthFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.locale = locale
                return formatter
            }()

            static let payoutWindowFormatter: DateIntervalFormatter = {
                let formatter = DateIntervalFormatter()
                formatter.locale = locale
                formatter.timeZone = timeZone
                formatter.dateTemplate = "MMMMd"
                return formatter
            }()

            static let payoutDateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.locale = locale
                formatter.timeZone = timeZone
                formatter.setLocalizedDateFormatFromTemplate("MMMMd")
                return formatter
            }()
        }
    }
}
