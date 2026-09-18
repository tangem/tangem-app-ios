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
            .verifyFeeDetails(title: "Fee", amount: "-$1.00", category: "Service fees")
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
            .verifyTangemPayTileSubtitle("2 cards")

        wireMockClient.setScenarioStateSync("tangem_pay_card_issue_order", state: "Started")

        issueCard(from: mainScreen, cardsStateAfterIssue: "ThreeCards")
            .verifyTangemPayTileSubtitle("3 cards")
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
}
