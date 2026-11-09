//
//  TangemPayMoneyAccountRowStateTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPay
@testable import Tangem

@Suite("Money account row on the main screen")
struct TangemPayMoneyAccountRowStateTests {
    @Test("An open account is shown as active whatever the verification says", arguments: [false, true])
    func openAccountIsActive(isKYCIncomplete: Bool) throws {
        let state = try TangemPayMoneyAccountRowState(
            moneyAccountState: .active(makeMoneyAccount(status: "COMPLETED")),
            isKYCIncomplete: isKYCIncomplete
        )

        #expect(state == .active)
    }

    @Test("The account waits for a deposit when its own activation step says so")
    func awaitingDepositStepHoldsTheAccount() throws {
        let state = try TangemPayMoneyAccountRowState(
            moneyAccountState: .activating(makeMoneyAccount(step: "AWAITING_DEPOSIT")),
            isKYCIncomplete: false
        )

        #expect(state == .awaitingDeposit)
    }

    @Test("Any other opening step shows the account as activating", arguments: [nil, "AWAITING_KYC", "ISSUING"])
    func otherStepsAreActivating(step: String?) throws {
        let state = try TangemPayMoneyAccountRowState(
            moneyAccountState: .activating(makeMoneyAccount(step: step)),
            isKYCIncomplete: false
        )

        #expect(state == .activating)
    }

    @Test("A failed opening shows the failed row")
    func failedOpeningIsFailed() throws {
        let state = try TangemPayMoneyAccountRowState(
            moneyAccountState: .activationFailed(makeMoneyAccount(status: "FAILED")),
            isKYCIncomplete: false
        )

        #expect(state == .failed)
    }

    @Test("An account that is not open yet has no row until the verification is passed", arguments: ["PROCESSING", "FAILED"])
    func unopenedAccountWaitsForVerification(status: String) throws {
        let moneyAccount = try makeMoneyAccount(status: status)
        let moneyAccountState: TangemPayMoneyAccountState = status == "FAILED" ? .activationFailed(moneyAccount) : .activating(moneyAccount)

        let state = TangemPayMoneyAccountRowState(moneyAccountState: moneyAccountState, isKYCIncomplete: true)

        #expect(state == nil)
    }

    @Test("An account that has not started, was closed or is not known has no row", arguments: HiddenState.allCases)
    func hiddenStatesHaveNoRow(hiddenState: HiddenState) throws {
        let state = try TangemPayMoneyAccountRowState(moneyAccountState: hiddenState.moneyAccountState(), isKYCIncomplete: false)

        #expect(state == nil)
    }

    @Test("Loading and failed refreshes carry no news about the account", arguments: HiddenState.allCases)
    func onlyRefreshStatesAreUnresolved(hiddenState: HiddenState) throws {
        let moneyAccountState = try #require(try hiddenState.moneyAccountState())

        #expect(moneyAccountState.isResolved == !hiddenState.isRefresh)
    }
}

// MARK: - Helpers

extension TangemPayMoneyAccountRowStateTests {
    enum HiddenState: CaseIterable {
        case notStarted
        case deactivated
        case loading
        case syncNeeded
        case unavailable

        var isRefresh: Bool {
            switch self {
            case .loading, .syncNeeded, .unavailable: true
            case .notStarted, .deactivated: false
            }
        }

        func moneyAccountState() throws -> TangemPayMoneyAccountState? {
            switch self {
            case .notStarted: .notStarted
            case .deactivated: try .deactivated(makeMoneyAccount(status: "DEACTIVATED"))
            case .loading: .loading
            case .syncNeeded: .syncNeeded
            case .unavailable: .unavailable
            }
        }
    }
}

private func makeMoneyAccount(status: String = "PROCESSING", step: String? = nil) throws -> TangemPayMoneyAccount {
    let stepJSON = step.map { #""\#($0)""# } ?? "null"
    let json = """
    {
      "id": null,
      "activation": { "status": "\(status)", "step": \(stepJSON), "failure_reason": null }
    }
    """

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let bankingAccount = try decoder.decode(TangemPayCustomerSummaryResponse.BankingAccount.self, from: Data(json.utf8))

    return TangemPayMoneyAccount(
        customerId: "customer",
        bankingAccount: bankingAccount,
        walletModel: WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil),
        customerService: CustomerInfoManagementServiceStub(),
        account: nil
    )
}
