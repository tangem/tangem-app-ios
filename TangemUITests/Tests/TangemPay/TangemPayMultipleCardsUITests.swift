//
//  TangemPayMultipleCardsUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayMultipleCardsUITests: BaseTestCase {
    func testIssueAdditionalCardPopup_ShowsFee_WhenBalanceCoversIt() {
        setAllureId(9731)

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
        ])

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains("$10.00")
            .tapAddCard()
            .waitForScreen()
            .selectVirtual()
            .waitForSheet()
            .verifyContent(feeValue: "$1.00")
            .verifyIssueCardEnabled()
    }

    func testIssueAdditionalCardPopup_ShowsUnableToCoverFee_WhenBalanceIsZero() {
        setAllureId(9732)

        let mainScreen = launchAndImportHotWallet()

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains("$0.00")
            .tapAddCard()
            .waitForScreen()
            .selectVirtual()
            .waitForSheet()
            .verifyContent(feeValue: "$1.00")
            .verifyUnableToCoverFee()
            .verifyIssueCardDisabled()
    }

    func testIssueAdditionalCard_BalanceBelowFee_OpensAddFunds() {
        setAllureId(9734)

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "BelowIssueFee"),
        ])

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains("$0.50")
            .tapAddCard()
            .waitForScreen()
            .selectVirtual()
            .waitForSheet()
            .verifyContent(feeValue: "$1.00")
            .verifyUnableToCoverFee()
            .verifyIssueCardDisabled()
            .tapAddFunds()
            .waitForScreen()
            .verifySwapAndReceiveOptions()
    }

    func testIssueSecondCard_ShowsIssuingStatusAndFeeTransaction() {
        setAllureId(9729)

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
            ScenarioConfig(name: "tangem_pay_card_issue_order", initialState: "Started"),
            ScenarioConfig(name: "tangem_pay_card_issue_orders", initialState: "Empty"),
            ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty"),
        ])

        let paymentAccount = mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains("$10.00")

        paymentAccount
            .tapAddCard()
            .waitForScreen()
            .selectVirtual()
            .waitForSheet()
            .verifyContent(feeValue: "$1.00")
            .tapIssueCard()
            .verifyIssuingCardBanner()

        wireMockClient.setScenarioStateSync("tangem_pay_balance_update", state: "AfterCardIssueFee")
        wireMockClient.setScenarioStateSync("tangem_pay_transaction_history", state: "AfterCardIssueFee")
        pullToRefresh()

        paymentAccount
            .verifyBalanceContains("$9.00")
            .verifyTransactionVisible(merchantName: "Card issue fee")
            .tapTransactionRow(containing: "Card issue fee")
            .waitForScreen()
            .verifyFeeDetails(title: Localization.tangemPayFeeTitle, amount: "-$1.00", category: Localization.tangemPayFeeSubtitle)
    }

    func testIssuingCard_ShowsProgressScreen() {
        setAllureId(10010)

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
            ScenarioConfig(name: "tangem_pay_card_issue_order", initialState: "Started"),
            ScenarioConfig(name: "tangem_pay_card_issue_orders", initialState: "Empty"),
        ])

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains("$10.00")
            .tapAddCard()
            .waitForScreen()
            .selectVirtual()
            .waitForSheet()
            .tapIssueCard()
            .verifyIssuingCardBanner()
            .tapIssuingCard()
            .verifyIssuingInProgress()
    }

    func testCardCounter_UpdatesOnPaymentAccountTile() {
        setAllureId(10018)

        // One card is the default customer response, so `tangem_pay_card_issue` stays unset here.
        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
            ScenarioConfig(name: "tangem_pay_card_issue_order", initialState: "Started"),
            ScenarioConfig(name: "tangem_pay_card_issue_orders", initialState: "Empty"),
        ])

        // A single card shows its masked number, the counter appears from the second card on.
        mainScreen.verifyTangemPayTileSubtitle("*4242")

        issueCard(from: mainScreen, cardsStateAfterIssue: "TwoCards")
            .verifyTangemPayTileSubtitle(Localization.tangempayCardsCount(2))

        wireMockClient.setScenarioStateSync("tangem_pay_card_issue_order", state: "Started")

        issueCard(from: mainScreen, cardsStateAfterIssue: "ThreeCards")
            .verifyTangemPayTileSubtitle(Localization.tangempayCardsCount(3))
    }

    func testActiveOrderAtLaunch_ShowsProgressScreen() {
        setAllureId(10014)
        wireMockClient.resetRequestJournalSync()

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: Constants.Scenario.balance, initialState: Constants.State.initialBalance),
            ScenarioConfig(name: Constants.Scenario.issueOrder, initialState: Constants.State.started),
            ScenarioConfig(name: Constants.Scenario.issueOrders, initialState: Constants.State.activeOrder),
        ])

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyIssuingCardBanner()
            .verifyAddCardDisabled()
            .tapIssuingCard()
            .verifyIssuingInProgress()

        XCTContext.runActivity(named: "Verify active orders were looked up at launch") { _ in
            XCTAssertGreaterThan(orderLookupRequestCount(), 0, "The app should look up active orders at launch")
        }
    }

    func testIssueCardWithActiveOrder_DoesNotPlaceNewOrder() {
        setAllureId(10008)

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: Constants.Scenario.balance, initialState: Constants.State.initialBalance),
            ScenarioConfig(name: Constants.Scenario.issueOrder, initialState: Constants.State.started),
            ScenarioConfig(name: Constants.Scenario.issueOrders, initialState: Constants.State.empty),
        ])

        let issueCardSheet = mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains(Constants.initialBalance)
            .tapAddCard()
            .waitForScreen()
            .selectVirtual()
            .waitForSheet()
            .verifyContent(feeValue: Constants.issueFee)

        wireMockClient.setScenarioStateSync(Constants.Scenario.issueOrders, state: Constants.State.activeOrder)
        wireMockClient.resetRequestJournalSync()

        let paymentAccount = issueCardSheet
            .tapIssueCard()
            .verifyIssuingCardBanner()

        XCTContext.runActivity(named: "Verify the existing order was reused instead of placing a new one") { _ in
            XCTAssertEqual(placeOrderRequestCount(), 0, "Confirming the issue with an active order should not place a new order")
        }

        paymentAccount
            .tapIssuingCard()
            .verifyIssuingInProgress()
    }

    private func issueCard(from mainScreen: MainScreen, cardsStateAfterIssue: String) -> MainScreen {
        let paymentAccount = mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains("$10.00")

        paymentAccount
            .tapAddCard()
            .waitForScreen()
            .selectVirtual()
            .waitForSheet()
            .tapIssueCard()
            .verifyIssuingCardBanner()

        wireMockClient.setScenarioStateSync("tangem_pay_card_issue", state: cardsStateAfterIssue)
        wireMockClient.setScenarioStateSync("tangem_pay_card_issue_order", state: "Completed")
        wireMockClient.setScenarioStateSync("tangem_pay_card_issue_orders", state: "Empty")

        return paymentAccount
            .waitForIssuingCardBannerHidden()
            .tapBack()
    }

    private func placeOrderRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Constants.Endpoint.order)
    }

    private func orderLookupRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "GET", urlPathPattern: Constants.Endpoint.order)
    }
}

private extension TangemPayMultipleCardsUITests {
    enum Constants {
        static let initialBalance = "$10.00"
        static let issueFee = "$1.00"

        enum Scenario {
            static let balance = "tangem_pay_balance_update"
            static let issueOrder = "tangem_pay_card_issue_order"
            static let issueOrders = "tangem_pay_card_issue_orders"
        }

        enum State {
            static let initialBalance = "InitialBalance"
            static let started = "Started"
            static let empty = "Empty"
            static let activeOrder = "ActiveOrder"
        }

        enum Endpoint {
            static let order = "/bff-v2/v1/order"
        }
    }
}
