//
//  TangemPayVirtualAccountUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayVirtualAccountUITests: BaseTestCase {
    func testOpenVirtualAccountViaAddFunds_ShowsBankingDetailsAfterOrderCompletes() {
        setAllureId(10292)

        let onboarding = openAddFunds(scenarios: [
            ScenarioConfig(name: Constants.Scenario.fees, initialState: Constants.State.started),
            ScenarioConfig(name: Constants.Scenario.order, initialState: Constants.State.started),
        ])
        .verifyBankTransferOptionDisplayed()
        .tapBankTransfer()
        .waitForScreen()
        .verifyFeeValue(.ach, equals: Constants.achFee)
        .verifyFeeValue(.fedwire, equals: Constants.fedwireFee)

        let ordersBefore = placeOrderRequestCount()

        onboarding
            .tapContinue()
            .verifyToastVisible(text: Localization.tangempayBankTransferRequestSent)
            .waitForScreen()

        XCTContext.runActivity(named: "Verify the Virtual account order was placed once") { _ in
            let placed = placeOrderRequestCount() - ordersBefore
            XCTAssertEqual(placed, 1, "Continue should place exactly one order, but delta was \(placed)")
        }

        // The account fixture goes first: the order poller reloads customer info as soon as it sees COMPLETED.
        wireMockClient.setScenarioStateSync(Constants.Scenario.account, state: Constants.State.accountActive)
        wireMockClient.setScenarioStateSync(Constants.Scenario.order, state: Constants.State.completed)

        let customerInfoBefore = customerInfoRequestCount()
        pullToRefresh()

        // Bank transfer routes to the Preparing popup until the activated account arrives in customer info.
        XCTContext.runActivity(named: "Verify customer info was reloaded after the refresh") { _ in
            let predicate = NSPredicate { _, _ in self.customerInfoRequestCount() > customerInfoBefore }
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .networkRequest),
                .completed,
                "Pull to refresh should reload customer info, but it made no request"
            )
        }

        TangemPayMainScreen(app)
            .tapAddFunds()
            .waitForScreen()
            .tapBankTransferExpectingDetails()
            .waitForScreen()
            .verifyDetail(.accountNumber, equals: Constants.accountNumber)
            .verifyDetail(.routingNumber, equals: Constants.routingNumber)
            .verifyDetail(.bankName, equals: Constants.bankName)
    }

    func testFeeScreen_WhenBackendReturnsBothFees_ShowsAchAndFedwire() {
        setAllureId(10871)

        openOnboarding(feesState: Constants.State.started)
            .verifyFeeValue(.ach, equals: Constants.achFee)
            .verifyFeeValue(.fedwire, equals: Constants.fedwireFee)
    }

    func testFeeScreen_WhenBackendReturnsAchOnly_HidesFedwire() {
        setAllureId(10872)

        openOnboarding(feesState: Constants.State.achOnly)
            .verifyFeeValue(.ach, equals: Constants.achFee)
            .verifyFeeNotDisplayed(.fedwire)
    }

    func testFeeScreen_WhenBackendReturnsFedwireOnly_HidesAch() {
        setAllureId(10873)

        openOnboarding(feesState: Constants.State.fedwireOnly)
            .verifyFeeValue(.fedwire, equals: Constants.fedwireFee)
            .verifyFeeNotDisplayed(.ach)
    }

    func testFeeScreen_WhenFeesUnavailable_ShowsErrorBannerAndReloadsOnTap() {
        setAllureId(11295)

        let onboarding = openOnboarding(feesState: Constants.State.unavailable)
            .verifyFeeErrorDisplayed()
            .verifyFeeNotDisplayed(.ach)
            .verifyFeeNotDisplayed(.fedwire)

        wireMockClient.setScenarioStateSync(Constants.Scenario.fees, state: Constants.State.started)

        onboarding
            .tapFeeErrorBanner()
            .verifyFeeValue(.ach, equals: Constants.achFee)
            .verifyFeeValue(.fedwire, equals: Constants.fedwireFee)
    }

    func testBankingDetails_ShowAllRequisitesAndDepositLimit() {
        setAllureId(10295)

        openAddFundsWithActiveAccount(bankCredentialsState: Constants.State.started)
            .tapBankTransferExpectingDetails()
            .waitForScreen()
            .verifyDetail(.beneficiaryName, equals: Constants.beneficiaryName)
            .verifyDetail(.beneficiaryAddress, equals: Constants.beneficiaryAddress)
            .verifyDetail(.bankName, equals: Constants.bankName)
            .verifyDetail(.bankAddress, equals: Constants.bankAddress)
            .verifyDetail(.accountNumber, equals: Constants.accountNumber)
            .verifyDetail(.routingNumber, equals: Constants.routingNumber)
            .verifyDepositLimit(Constants.depositLimit)
    }

    func testBankingDetailsError_RetryLoadsRequisites() {
        setAllureId(10297)

        let errorSheet = openAddFundsWithActiveAccount(bankCredentialsState: Constants.State.error)
            .tapBankTransferExpectingError()
            .waitForScreen()
            .verifySheetContent()

        wireMockClient.setScenarioStateSync(Constants.Scenario.bankCredentials, state: Constants.State.started)

        let requestsBeforeRetry = bankCredentialsRequestCount()

        errorSheet
            .tapRetry()
            .waitForScreen()
            .verifyDetail(.accountNumber, equals: Constants.accountNumber)
            .verifyDetail(.routingNumber, equals: Constants.routingNumber)

        XCTContext.runActivity(named: "Verify Retry requested the banking details again") { _ in
            XCTAssertGreaterThan(
                bankCredentialsRequestCount(),
                requestsBeforeRetry,
                "Retry should request the bank credentials endpoint again"
            )
        }
    }

    private func openOnboarding(feesState: String) -> TangemPayVirtualAccountOnboardingScreen {
        openAddFunds(scenarios: [ScenarioConfig(name: Constants.Scenario.fees, initialState: feesState)])
            .verifyBankTransferOptionDisplayed()
            .tapBankTransfer()
            .waitForScreen()
    }

    private func openAddFundsWithActiveAccount(bankCredentialsState: String) -> TangemPayAddFundsSheet {
        openAddFunds(scenarios: [
            ScenarioConfig(name: Constants.Scenario.fees, initialState: Constants.State.started),
            ScenarioConfig(name: Constants.Scenario.account, initialState: Constants.State.accountActive),
            ScenarioConfig(name: Constants.Scenario.bankCredentials, initialState: bankCredentialsState),
        ])
        .verifyBankTransferOptionDisplayed()
    }

    private func openAddFunds(scenarios: [ScenarioConfig]) -> TangemPayAddFundsSheet {
        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: Constants.Scenario.channels, initialState: Constants.State.virtualAccount),
            ScenarioConfig(name: Constants.Scenario.balance, initialState: Constants.State.initialBalance),
            ScenarioConfig(name: Constants.Scenario.transactionHistory, initialState: Constants.State.initialEmpty),
        ] + scenarios)
            .openTangemPay()
            .waitForScreen()
            .tapAddFunds()
            .waitForScreen()
    }

    private func bankCredentialsRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "GET", urlPathPattern: Constants.Endpoint.bankCredentials)
    }

    private func placeOrderRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Constants.Endpoint.placeOrder)
    }

    private func customerInfoRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "GET", urlPathPattern: Constants.Endpoint.customerInfo)
    }
}

private extension TangemPayVirtualAccountUITests {
    enum Constants {
        static let achFee = "$1.5"
        static let fedwireFee = "$25"
        static let depositLimit = "$10,000"
        static let beneficiaryName = "Hot Wallet User"
        static let beneficiaryAddress = "1 Market St, San Francisco, CA 94105"
        static let bankName = "Lead Bank"
        static let bankAddress = "1801 Main St, Kansas City, MO 64108"
        static let accountNumber = "1234567890"
        static let routingNumber = "101019644"

        enum Scenario {
            static let channels = "tangem_pay_eligibility_channels"
            static let balance = "tangem_pay_balance_update"
            static let transactionHistory = "tangem_pay_transaction_history"
            static let fees = "tangem_pay_onramp_fees"
            static let order = "tangem_pay_virtual_account_order"
            static let account = "tangem_pay_virtual_account"
            static let bankCredentials = "tangem_pay_bank_credentials"
        }

        enum State {
            static let started = "Started"
            static let virtualAccount = "VirtualAccount"
            static let initialBalance = "InitialBalance"
            static let initialEmpty = "InitialEmpty"
            static let accountActive = "AccountActive"
            static let completed = "Completed"
            static let achOnly = "AchOnly"
            static let fedwireOnly = "FedwireOnly"
            static let unavailable = "Unavailable"
            static let error = "Error"
        }

        enum Endpoint {
            static let bankCredentials = "/bff-v2/v1/account/bank-credentials/mock-va-product-id"
            static let placeOrder = "/bff-v2/v1/order"
            static let customerInfo = "/bff-v2/v1/customer/me"
        }
    }
}
