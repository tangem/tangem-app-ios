//
//  TangemPayVirtualAccountUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayVirtualAccountUITests: BaseTestCase {
    private let channelsScenario = "tangem_pay_eligibility_channels"
    private let feesScenario = "tangem_pay_onramp_fees"
    private let orderScenario = "tangem_pay_virtual_account_order"
    private let accountScenario = "tangem_pay_virtual_account"
    private let placeOrderEndpointPattern = "/bff-v2/v1/order"
    private let customerInfoEndpointPattern = "/bff-v2/v1/customer/me"
    private let achFee = "$1.5"
    private let fedwireFee = "$25"

    func testOpenVirtualAccountViaAddFunds_ShowsBankingDetailsAfterOrderCompletes() {
        setAllureId(10292)

        let infoSheet = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: channelsScenario, initialState: "VirtualAccount"),
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
            ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty"),
            ScenarioConfig(name: feesScenario, initialState: "Started"),
            ScenarioConfig(name: orderScenario, initialState: "Started"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapAddFunds()
        .waitForScreen()
        .verifyBankTransferOptionDisplayed()
        .tapBankTransfer()
        .waitForScreen()
        .verifyFeeValue(.ach, equals: achFee)
        .verifyFeeValue(.fedwire, equals: fedwireFee)

        let ordersBefore = placeOrderRequestCount()

        infoSheet
            .tapShowDetailsExpectingSuccess()
            .waitForScreen()
            .tapClose()
            .waitForScreen()

        XCTContext.runActivity(named: "Verify the Virtual account order was placed once") { _ in
            let placed = placeOrderRequestCount() - ordersBefore
            XCTAssertEqual(placed, 1, "Show details should place exactly one order, but delta was \(placed)")
        }

        // The account fixture goes first: the order poller reloads customer info as soon as it sees COMPLETED.
        wireMockClient.setScenarioStateSync(accountScenario, state: "AccountActive")
        wireMockClient.setScenarioStateSync(orderScenario, state: "Completed")

        let customerInfoBefore = customerInfoRequestCount()
        pullToRefresh()

        // Bank transfer routes to the Preparing popup until the activated account arrives in customer info.
        XCTContext.runActivity(named: "Verify customer info was reloaded after the refresh") { _ in
            let reloads = customerInfoRequestCount() - customerInfoBefore
            XCTAssertGreaterThan(reloads, 0, "Pull to refresh should reload customer info, but it made no request")
        }

        TangemPayMainScreen(app)
            .tapAddFunds()
            .waitForScreen()
            .tapBankTransfer()
            .waitForScreen()
            .tapShowDetailsExpectingBankDetails()
            .waitForScreen()
            .verifyDetail(.accountNumber, equals: "1234567890")
            .verifyDetail(.routingNumber, equals: "101019644")
            .verifyDetail(.bankName, equals: "Lead Bank")
    }

    func testFeeScreen_WhenBackendReturnsBothFees_ShowsAchAndFedwire() {
        setAllureId(10871)

        openBankTransferFeeSheet(feesState: "Started")
            .verifyFeeValue(.ach, equals: achFee)
            .verifyFeeValue(.fedwire, equals: fedwireFee)
    }

    func testFeeScreen_WhenBackendReturnsAchOnly_HidesFedwire() {
        setAllureId(10872)

        openBankTransferFeeSheet(feesState: "AchOnly")
            .verifyFeeValue(.ach, equals: achFee)
            .verifyFeeNotDisplayed(.fedwire)
    }

    func testFeeScreen_WhenBackendReturnsFedwireOnly_HidesAch() {
        setAllureId(10873)

        openBankTransferFeeSheet(feesState: "FedwireOnly")
            .verifyFeeValue(.fedwire, equals: fedwireFee)
            .verifyFeeNotDisplayed(.ach)
    }

    func testFeeScreen_WhenFeesUnavailable_ShowsErrorBannerAndReloadsOnTap() {
        setAllureId(11295)

        let infoSheet = openBankTransferFeeSheet(feesState: "Unavailable")
            .verifyFeeErrorDisplayed()
            .verifyFeeNotDisplayed(.ach)
            .verifyFeeNotDisplayed(.fedwire)

        wireMockClient.setScenarioStateSync(feesScenario, state: "Started")

        infoSheet
            .tapFeeErrorBanner()
            .verifyFeeValue(.ach, equals: achFee)
            .verifyFeeValue(.fedwire, equals: fedwireFee)
    }

    private func openBankTransferFeeSheet(feesState: String) -> TangemPayVirtualAccountInfoSheet {
        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: channelsScenario, initialState: "VirtualAccount"),
            ScenarioConfig(name: "tangem_pay_balance_update", initialState: "InitialBalance"),
            ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty"),
            ScenarioConfig(name: feesScenario, initialState: feesState),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapAddFunds()
        .waitForScreen()
        .verifyBankTransferOptionDisplayed()
        .tapBankTransfer()
        .waitForScreen()
    }

    private func placeOrderRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: placeOrderEndpointPattern)
    }

    private func customerInfoRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "GET", urlPathPattern: customerInfoEndpointPattern)
    }
}
