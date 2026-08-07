//
//  TangemPayReissueUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayReissueUITests: BaseTestCase {
    func testReissueBottomSheet_DisplaysReplaceCardDetails() {
        setAllureId(9749)

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
            ScenarioConfig(name: "tangem_pay_card_reissue", initialState: "Started"),
        ])

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()
            .tapReplaceCard()
            .waitForSheet()
            .verifyReplaceCardContent(feeValue: "$1.00")
    }

    func testReissueFeeError_ShowsAlert_WhenFeeRequestFails() {
        setAllureId(9750)

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_card_reissue", initialState: "FeeError"),
        ])

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()
            .tapReplaceCardExpectingFeeError()
            .verifyFeeUnreachableAlertAndDismiss()
    }

    func testReissueFeeTransaction_AppearsInHistoryAndDetails() {
        setAllureId(9752)

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
            ScenarioConfig(name: "tangem_pay_card_reissue", initialState: "Started"),
            ScenarioConfig(name: "tangem_pay_reissue_order", initialState: "Started"),
            ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty"),
        ])

        let paymentAccount = mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()
            .tapReplaceCard()
            .waitForSheet()
            .tapConfirm()
            .tapBack()
            .waitForScreen()

        wireMockClient.setScenarioStateSync("tangem_pay_transaction_history", state: "AfterReissueFee")
        pullToRefresh()

        paymentAccount
            .verifyTransactionVisible(merchantName: "Card replacement fee")
            .tapTransactionRow(containing: "Card replacement fee")
            .waitForScreen()
            .verifyFeeDetails(title: "Fee", amount: "-$1.00", category: "Service fees")
    }

    func testReissueEndToEnd_ReplacesCardWithNewDetails() {
        setAllureId(9743)

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
            ScenarioConfig(name: "tangem_pay_card_reissue", initialState: "Started"),
            ScenarioConfig(name: "tangem_pay_reissue_order", initialState: "Started"),
        ])

        let cardDetails = mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()

        cardDetails
            .tapShowDetails()
            .waitForRevealedDetails()

        let oldNumber = cardDetails.readCardNumber()

        cardDetails
            .tapReplaceCard()
            .waitForSheet()
            .tapConfirm()
            .verifyReplacingInProgress()

        wireMockClient.setScenarioStateSync("tangem_pay_reissue_order", state: "Completed")
        wireMockClient.setScenarioStateSync("tangem_pay_reissue", state: "Completed")

        cardDetails.waitForReissueCompleted()

        let reopenedCard = cardDetails
            .tapBack()
            .waitForScreen()
            .tapCard()
            .waitForScreen()

        reopenedCard
            .tapShowDetails()
            .waitForRevealedDetails()

        let newNumber = reopenedCard.readCardNumber()

        XCTAssertNotEqual(oldNumber, newNumber, "Card number should differ after reissue")
    }

    func testReissueTopUp_UnableToCoverFee_AddFundsSwapAndReceive() {
        setAllureId(9746)

        let mainScreen = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_card_reissue", initialState: "Started"),
        ])

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()
            .tapReplaceCard()
            .waitForSheet()
            .verifyUnableToCoverFee()
            .tapAddFunds()
            .waitForScreen()
            .verifySwapAndReceiveOptions()
            .tapReceive()
            .verifyDepositInfo(network: "Polygon")
    }
}
