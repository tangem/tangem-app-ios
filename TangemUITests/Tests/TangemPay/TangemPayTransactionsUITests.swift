//
//  TangemPayTransactionsUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayTransactionsUITests: BaseTestCase {
    private static let transactionsEndpointPath = "/bff-v2/v1/customer/transactions"
    private static let nextPageEndpointPattern = "/bff-v2/v1/customer/transactions\\?.*cursor=page1-20.*"
    private static let historyScenario = "tangem_pay_transaction_history"

    func testTransactionsRequested_WhenPaymentAccountOpens() {
        setAllureId(9545)

        let mainScreen = launchWithTransactionHistory(state: "SpendCompleted")
        let requestsBeforeOpening = transactionsRequestCount()

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyTransactionRow(name: "Tangem Coffee")

        XCTContext.runActivity(named: "Verify transaction history was requested") { _ in
            let requestsAfterOpening = transactionsRequestCount()
            XCTAssertGreaterThan(
                requestsAfterOpening,
                requestsBeforeOpening,
                "Opening Payment account should request /customer/transactions"
            )
        }
    }

    func testTransactionHistoryErrorState_ReloadRefetchesHistory() {
        setAllureId(9532)

        let payScreen = launchWithTransactionHistory(state: "HistoryError")
            .openTangemPay()
            .waitForScreen()
            .verifyHistoryErrorState()

        wireMockClient.setScenarioStateSync(Self.historyScenario, state: "SpendCompleted")

        let requestsBeforeReload = transactionsRequestCount()

        payScreen
            .tapReloadHistory()
            .verifyTransactionRow(name: "Tangem Coffee", amount: "-$12.34", category: "Restaurants")

        XCTContext.runActivity(named: "Verify Reload requested the history again") { _ in
            let requestsAfterReload = transactionsRequestCount()
            XCTAssertGreaterThan(
                requestsAfterReload,
                requestsBeforeReload,
                "Reload should request /customer/transactions again"
            )
        }
    }

    func testNextPageRequestedWithCursor_WhenHistoryScrolledToBottom() {
        setAllureId(9546)

        let payScreen = launchWithTransactionHistory(state: "HistoryFirstPage")
            .openTangemPay()
            .waitForScreen()
            .verifyTransactionRow(name: "Merchant 01")

        let cursorRequestsBeforeScroll = nextPageRequestCount()

        payScreen
            .scrollToTransaction(name: "Second Page 1")
            .verifyTransactionRow(name: "Second Page 1")

        XCTContext.runActivity(named: "Verify next page was requested with the cursor parameter") { _ in
            let cursorRequestsAfterScroll = nextPageRequestCount()
            XCTAssertGreaterThan(
                cursorRequestsAfterScroll,
                cursorRequestsBeforeScroll,
                "Scrolling to the bottom should request /customer/transactions with the cursor parameter"
            )
        }
    }

    func testSpendTransaction_ShownInListAndDetails() {
        setAllureId(9581)

        let payScreen = launchWithTransactionHistory(state: "SpendCompleted")
            .openTangemPay()
            .waitForScreen()
            .verifySectionHeader("April 23, 2026")
            .verifyTransactionRow(name: "Tangem Coffee", amount: "-$12.34", category: "Restaurants")

        payScreen
            .tapTransaction(name: "Tangem Coffee")
            .waitForScreen()
            .verifyHeader(title: "Purchase", dateContains: "Apr 23 2026")
            .verifyIconVisible()
            .verifyAmount("-$12.34")
            .verifyGetHelpButton()
    }

    func testCompletedTransaction_DetailsShowCompletedStatus() {
        setAllureId(9539)

        launchWithTransactionHistory(state: "SpendCompleted")
            .openTangemPay()
            .waitForScreen()
            .tapTransaction(name: "Tangem Coffee")
            .waitForScreen()
            .verifyHeader(title: "Purchase", dateContains: "Apr 23 2026")
            .verifyIconVisible()
            .verifyAmount("-$12.34")
            .verifyStatus("Completed")
            .verifyGetHelpButton()
    }

    private func launchWithTransactionHistory(state: String) -> MainScreen {
        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
            ScenarioConfig(name: Self.historyScenario, initialState: state),
        ])
    }

    private func transactionsRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "GET", urlPathPattern: Self.transactionsEndpointPath)
    }

    private func nextPageRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "GET", urlPattern: Self.nextPageEndpointPattern)
    }
}
