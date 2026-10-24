//
//  TangemPayCardFreezeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayCardFreezeUITests: BaseTestCase {
    /// [REDACTED_INFO] Tangem Pay card management stays in "freezing/unfreezing in progress" after a successful freeze or unfreeze
    func skipped_testFreezeCard_ShowsErrorToast_ThenRetrySucceeds() {
        setAllureId(9555)

        let mainScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_card_freeze", initialState: "FreezeError")]
        )

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()
            .verifyCardActive()
            .tapFreezeCard()
            .waitForScreen()
            .confirmFreeze()
            .verifyFreezeErrorToast()
            .verifyCardActive()
            .tapFreezeCard()
            .waitForScreen()
            .confirmFreeze()
            .verifyCardFrozen()
    }

    /// [REDACTED_INFO] Tangem Pay card management stays in "freezing/unfreezing in progress" after a successful freeze or unfreeze
    func skipped_testUnfreezeCard_ShowsErrorToast_ThenRetrySucceeds() {
        setAllureId(9556)

        let mainScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_card_freeze", initialState: "UnfreezeError")]
        )

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()
            .verifyCardFrozen()
            .tapUnfreezeCard()
            .waitForScreen()
            .confirmUnfreeze()
            .verifyUnfreezeErrorToast()
            .verifyCardFrozen()
            .tapUnfreezeCard()
            .waitForScreen()
            .confirmUnfreeze()
            .verifyCardActive()
    }

    func testWithdrawAndAddFundsDisabled_WhenCardIsFrozen() {
        setAllureId(9608)

        let mainScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_card_freeze", initialState: "Frozen")]
        )

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .waitForBalanceLoaded()
            .verifyWithdrawDisabled()
            .verifyAddFundsDisabled()
    }

    func testFrozenCard_ShowsSnowflakeIndicatorOnPaymentAccount() {
        setAllureId(11478)

        launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: Constants.Scenario.cardFreeze, initialState: Constants.State.cardActive)]
        )
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .verifyCardActive()
        .tapFreezeCard()
        .waitForScreen()
        .confirmFreeze()
        .verifyCardFrozen()
        .tapBack()
        .waitForScreen()
        .verifyCardFrozenIndicator(cardId: Constants.cardId)
    }

    func testPaymentOnFrozenCard_ShownAsDeclinedZeroAmountTransaction() {
        setAllureId(9533)

        let cardDetails = launchAndImportHotWallet(
            scenarios: [
                ScenarioConfig(name: Constants.Scenario.cardFreeze, initialState: Constants.State.cardActive),
                ScenarioConfig(name: Constants.Scenario.balance, initialState: Constants.State.initialBalance),
                ScenarioConfig(name: Constants.Scenario.history, initialState: Constants.State.emptyHistory),
            ]
        )
        .openTangemPay()
        .waitForScreen()
        .verifyEmptyTransactionsState()
        .tapCard()
        .waitForScreen()
        .verifyCardActive()
        .tapFreezeCard()
        .waitForScreen()
        .confirmFreeze()
        .verifyCardFrozen()

        wireMockClient.setScenarioStateSync(Constants.Scenario.history, state: Constants.State.declinedOnFrozenCard)

        cardDetails
            .tapBack()
            .waitForScreen()
            .tapBack()
            .openTangemPay()
            .waitForScreen()
            .verifyTransactionRow(
                name: Constants.DeclinedTransaction.merchant,
                amount: Constants.DeclinedTransaction.amount,
                category: Constants.DeclinedTransaction.category
            )
            .tapTransaction(name: Constants.DeclinedTransaction.merchant)
            .waitForScreen()
            .verifyAmount(Constants.DeclinedTransaction.amount)
            .verifyStatus(Localization.tangemPayStatusDeclined)
    }
}

private extension TangemPayCardFreezeUITests {
    enum Constants {
        static let cardId = "mock-card-id"

        enum Scenario {
            static let cardFreeze = "tangem_pay_card_freeze"
            static let balance = "tangem_pay_balance_update"
            static let history = "tangem_pay_transaction_history"
        }

        enum State {
            static let cardActive = "Started"
            static let initialBalance = "InitialBalance"
            static let emptyHistory = "InitialEmpty"
            static let declinedOnFrozenCard = "SpendDeclinedFrozenCard"
        }

        enum DeclinedTransaction {
            static let merchant = "Tangem Frozen Card Shop"
            static let amount = "$0.00"
            static let category = "Electronics"
        }
    }
}
