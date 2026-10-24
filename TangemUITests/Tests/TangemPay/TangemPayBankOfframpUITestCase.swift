//
//  TangemPayBankOfframpUITestCase.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

class TangemPayBankOfframpUITestCase: BaseTestCase {
    enum ChannelsState: String {
        case bankOfframp = "BankOfframp"
        case withoutBankOfframp = "BannerAndDetails"
    }

    enum BalanceState: String {
        case initial = "InitialBalanceMultinetwork"
        case multiNetworkStatuses = "MultiNetworkStatuses"
        case arbitrumTopUp = "MultiNetworkArbitrumTopUp"
        case bankOfframp = "MultiNetworkBankOfframp"
    }

    enum BankAccountsState: String {
        case empty = "Started"
        case twoAccounts = "TwoAccounts"
        case fiveAccounts = "FiveAccounts"
        case afterTransfer = "AfterTransfer"
        case twoAccountsAfterTransfer = "TwoAccountsAfterTransfer"
        case error = "Error"
    }

    enum OfframpOptionsState: String {
        case available = "Started"
        case empty = "Empty"
        case error = "Error"
    }

    enum Endpoint: String {
        case eligibilityChannels = "/bff-v2/v1/eligibility/channels"
        case bankAccounts = "/bff-v2/v1/account/bank-accounts"
        case offrampOptions = "/bff-v2/v1/account/bank-offramp/options"
        case order = "/bff-v2/v1/order"
        case orderStatus = "/bff-v2/v1/order/mock-bank-offramp-order-001"
        case orderSignature = "/bff-v2/v1/order/.*/bank-offramp/signature"
        case withdrawData = "/bff-v2/v1/customer/card/withdraw/data"
    }

    func openPaymentAccount(
        balance: BalanceState = .initial,
        bankAccounts: BankAccountsState = .empty,
        offrampOptions: OfframpOptionsState = .available,
        extraScenarios: [ScenarioConfig] = []
    ) -> TangemPayMainScreen {
        launchAndImportHotWalletWithRealPayAuthorization(expressApiType: .mock, scenarios: [
            ScenarioConfig(name: Constants.Scenario.eligibilityChannels, initialState: ChannelsState.bankOfframp.rawValue),
            ScenarioConfig(name: Constants.Scenario.balance, initialState: balance.rawValue),
            ScenarioConfig(name: Constants.Scenario.history, initialState: Constants.State.emptyHistory),
            ScenarioConfig(name: Constants.Scenario.bankAccounts, initialState: bankAccounts.rawValue),
            ScenarioConfig(name: Constants.Scenario.offrampOptions, initialState: offrampOptions.rawValue),
        ] + extraScenarios)
            .openTangemPay()
            .waitForScreen()
            .waitForBalanceLoaded()
    }

    func switchEligibilityChannels(to state: ChannelsState) {
        XCTContext.runActivity(named: "Switch the eligibility channels to \(state.rawValue)") { _ in
            wireMockClient.setScenarioStateSync(Constants.Scenario.eligibilityChannels, state: state.rawValue)
        }
    }

    func switchBalance(to state: BalanceState) {
        XCTContext.runActivity(named: "Switch the balance to \(state.rawValue)") { _ in
            wireMockClient.setScenarioStateSync(Constants.Scenario.balance, state: state.rawValue)
        }
    }

    func switchBankAccounts(to state: BankAccountsState) {
        XCTContext.runActivity(named: "Switch the bank accounts to \(state.rawValue)") { _ in
            wireMockClient.setScenarioStateSync(Constants.Scenario.bankAccounts, state: state.rawValue)
        }
    }

    func switchOfframpOptions(to state: OfframpOptionsState) {
        XCTContext.runActivity(named: "Switch the off-ramp options to \(state.rawValue)") { _ in
            wireMockClient.setScenarioStateSync(Constants.Scenario.offrampOptions, state: state.rawValue)
        }
    }

    func requestCount(_ endpoint: Endpoint, method: String = "GET") -> Int {
        wireMockClient.requestCountSync(method: method, urlPathPattern: endpoint.rawValue)
    }

    func verifyRequestedAgain(_ endpoint: Endpoint, method: String = "GET", since previousCount: Int, _ message: String) {
        verifyRequestCount(endpoint, method: method, exceeds: previousCount, message)
    }

    func verifyRequestCount(_ endpoint: Endpoint, method: String = "GET", exceeds count: Int, _ message: String) {
        XCTContext.runActivity(named: "Verify \(method) \(endpoint.rawValue) was requested more than \(count) times") { _ in
            let requested = NSPredicate { _, _ in
                self.requestCount(endpoint, method: method) > count
            }
            let expectation = XCTNSPredicateExpectation(predicate: requested, object: nil)
            XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: .conditional), .completed, message)
        }
    }

    func bankOfframpOrderCount(matching expected: TangemPayBankOfframpOrderRequest) -> Int {
        wireMockClient
            .findRequestBodiesSync(method: "POST", urlPath: Endpoint.order.rawValue)
            .compactMap(TangemPayBankOfframpOrderRequest.init(body:))
            .filter { $0 == expected }
            .count
    }

    func verifyBankOfframpOrderSent(_ expected: TangemPayBankOfframpOrderRequest, since previousCount: Int) {
        XCTContext.runActivity(named: "Verify the bank off-ramp order \(expected) was placed") { _ in
            let placed = NSPredicate { _, _ in
                self.bankOfframpOrderCount(matching: expected) > previousCount
            }
            let expectation = XCTNSPredicateExpectation(predicate: placed, object: nil)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .networkRequest),
                .completed,
                "POST \(Endpoint.order.rawValue) should carry \(expected)"
            )
        }
    }
}

private extension TangemPayBankOfframpUITestCase {
    enum Constants {
        enum Scenario {
            static let eligibilityChannels = "tangem_pay_eligibility_channels"
            static let balance = "tangem_pay_balance_update"
            static let history = "tangem_pay_transaction_history"
            static let bankAccounts = "tangem_pay_bank_accounts"
            static let offrampOptions = "tangem_pay_bank_offramp_options"
        }

        enum State {
            static let emptyHistory = "InitialEmpty"
        }
    }
}
