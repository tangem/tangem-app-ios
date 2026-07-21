//
//  TangemPayUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayUITests: BaseTestCase {
    func testChangePin_SetsNewPinCode_FromCardDetails() {
        setAllureId(4549)

        let mainScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_pin_setup", initialState: "PinNotSet")]
        )

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()
            .tapChangePin()
            .waitForPinEntryScreen()
            .enterPin("5217")
            .waitForSuccessScreen()
            .tapDone()
            .waitForScreen()
    }

    func testBalanceUpdatesAfterTransaction_OnPaymentAccountScreen() {
        setAllureId(4969)

        let mainScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance")]
        )

        let mainAfterBack = mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains("10")
            .tapBack()

        // Simulate a $1 transaction on the Tangem Pay
        wireMockClient.setScenarioStateSync("tangem_pay_balance_update", state: "AfterTransaction")

        mainAfterBack
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains("9")
    }

    func testTransactionList_NewTransactionAppears_AfterMockedCharge() {
        setAllureId(4970)

        let mainScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty")]
        )

        let mainAfterBack = mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyTransactionNotVisible(merchantName: "Mock Merchant")
            .tapBack()

        // Simulate a new transaction on the Tangem Pay
        wireMockClient.setScenarioStateSync("tangem_pay_transaction_history", state: "AfterTransaction")

        mainAfterBack
            .openTangemPay()
            .waitForScreen()
            .verifyTransactionVisible(merchantName: "Mock Merchant")
    }

    func testFreezeUnfreezeCard_TogglesCardState() {
        setAllureId(4971)

        let mainScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_card_freeze", initialState: "Started")]
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
            .verifyCardFrozen()
            .tapUnfreezeCard()
            .waitForScreen()
            .confirmUnfreeze()
            .verifyCardActive()
    }

    func testRevealAndCopyCardDetails_NumberExpirationCVC() {
        setAllureId(4974)

        let cardDetailsScreen = launchAndImportHotWallet()
            .openTangemPay()
            .waitForScreen()
            .tapCard()
            .waitForScreen()
            .tapShowDetails()
            .waitForRevealedDetails()

        cardDetailsScreen
            .tapCopyCardNumber()
            .verifyToastVisible(text: "Number copied")
            .tapCopyExpiration()
            .verifyToastVisible(text: "Expiration date copied")
            .tapCopyCvc()
            .verifyToastVisible(text: "CVC copied")
    }

    func testTermsAndFees_OpensTariffsWebView_FromMoreActionsMenu() {
        setAllureId(9592)

        launchAndImportHotWallet()
            .openTangemPay()
            .waitForScreen()
            .openTermsAndFees()
            .verifyWebViewLoaded()
            .verifyDocumentTitle()
    }

    func testAddFunds_ShowsServiceUnavailableError_WhenNoDepositAddress() {
        setAllureId(9557)

        let mainScreen = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: "tangem_pay_deposit_address", initialState: "NoDepositAddress")]
        )

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .tapAddFundsExpectingServiceUnavailable()
            .waitForSheet()
            .tapGotIt()
            .waitForScreen()
    }
}
