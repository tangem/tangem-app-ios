//
//  TransactionDetailsOnrampAmountTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import TangemUI
@testable import Tangem

/// The received leg carries the whole state signal on the details sheet: a tilde while the provider is still
/// working, a plus once the crypto lands, and a struck-through promise when the deal failed. The history row derives its
/// own sign from the same stage but through a different type, so drift here is invisible until the two
/// surfaces disagree about whether a figure is an estimate or a delivery.
@Suite("Transaction details onramp amounts")
struct TransactionDetailsOnrampAmountTests {
    private static let stages: [TransactionDetailsOperationStage] = [.inProgress, .finished, .unsuccessful]

    @Test("In-progress marks the received amount as an estimate")
    func inProgressReceivedAmountIsEstimated() throws {
        let legs = try #require(makeViewData(stage: .inProgress, receivedAmount: "1800").legs)

        #expect(legs.to.amountText == "~\u{a0}1800\u{a0}POL")
    }

    @Test("Finished signs the received amount as a delivery")
    func finishedReceivedAmountIsSigned() throws {
        let legs = try #require(makeViewData(stage: .finished, receivedAmount: "1800").legs)

        #expect(legs.to.amountText == "+\u{a0}1800\u{a0}POL")
    }

    @Test("A settled top-up with no known amount falls back to a dash", arguments: [nil, ""] as [String?])
    func finishedWithoutAmountIsDash(amount: String?) throws {
        let legs = try #require(makeViewData(stage: .finished, receivedAmount: amount).legs)

        #expect(legs.to.amountText == AppConstants.enDashSign)
    }

    @Test("An unsuccessful top-up strikes through the amount the provider promised")
    func unsuccessfulStrikesThroughPromisedAmount() throws {
        let legs = try #require(makeViewData(stage: .unsuccessful, receivedAmount: "1800").legs)

        #expect(legs.to.amountText == "1800\u{a0}POL")
        #expect(legs.to.isAmountStrikethrough)
    }

    @Test("An unsuccessful top-up the provider never quoted shows a plain dash")
    func unsuccessfulWithoutAmountIsPlainDash() throws {
        let legs = try #require(makeViewData(stage: .unsuccessful, receivedAmount: nil).legs)

        #expect(legs.to.amountText == AppConstants.enDashSign)
        #expect(!legs.to.isAmountStrikethrough)
    }

    @Test("Only the received amount of an unsuccessful top-up is struck through", arguments: stages)
    func onlyUnsuccessfulReceivedAmountIsStruckThrough(stage: TransactionDetailsOperationStage) throws {
        let legs = try #require(makeViewData(stage: stage, receivedAmount: "1800").legs)

        #expect(!legs.from.isAmountStrikethrough)
        #expect(legs.to.isAmountStrikethrough == (stage == .unsuccessful))
    }

    @Test("The paid amount is never signed", arguments: stages)
    func paidAmountIsNeverSigned(stage: TransactionDetailsOperationStage) throws {
        let legs = try #require(makeViewData(stage: stage, receivedAmount: "1800").legs)

        #expect(legs.from.amountText == "100\u{a0}EUR")
    }

    @Test("Neither leg carries a fiat value", arguments: stages)
    func noLegCarriesFiat(stage: TransactionDetailsOperationStage) throws {
        let legs = try #require(makeViewData(stage: stage, receivedAmount: "1800").legs)

        #expect(legs.from.fiatText == nil)
        #expect(legs.to.fiatText == nil)
    }
}

// MARK: - Fixtures

private extension TransactionDetailsOnrampAmountTests {
    func makeViewData(
        stage: TransactionDetailsOperationStage,
        receivedAmount: String?
    ) -> TransactionDetailsOnrampViewData {
        TransactionDetailsOnrampViewData(
            stage: stage,
            paid: TransactionDetailsOnrampViewData.PaidLeg(
                amount: "100",
                symbol: "EUR",
                flagIconURL: nil,
                isFlagLoading: false
            ),
            received: TransactionDetailsOnrampViewData.ReceivedLeg(
                destination: .wallet(name: "Wallet"),
                amount: receivedAmount,
                symbol: "POL",
                tokenIconInfo: .remote(name: "Polygon", imageURL: nil)
            ),
            statusBanner: nil,
            provider: nil,
            rate: nil,
            action: nil
        )
    }
}

private extension TransactionDetailsOnrampViewData {
    var legs: (from: TransactionDetailsTokensViewData.Leg, to: TransactionDetailsTokensViewData.Leg)? {
        guard case .pair(let from, let to) = tokensData.content else {
            return nil
        }

        return (from, to)
    }
}
