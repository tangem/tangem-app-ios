//
//  TransactionDetailsProviderNavigationSourceTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import TangemExpress

/// The navigation source drives both the provider button the sheet draws and the `Notice - KYC` /
/// `Notice - Long Time Transaction` events, so a change here silently moves the analytics too.
@Suite("TransactionDetailsFactory.providerNavigationSource")
struct TransactionDetailsProviderNavigationSourceTests {
    /// Anything above the 15 minute threshold the sheet uses to call a swap long-running.
    private let longAgo = Date().addingTimeInterval(-20 * 60)

    // MARK: - Onramp

    @Test
    func onrampAwaitingVerificationReportsKYC() {
        #expect(source(forOnramp: .verifying) == .kyc)
    }

    @Test(arguments: [OnrampTransactionStatus.paused, .waitingForPayment])
    func onrampWaitingOnTheProviderReportsTheStatusBlock(status: OnrampTransactionStatus) {
        #expect(source(forOnramp: status) == .status)
    }

    @Test(arguments: [
        OnrampTransactionStatus.unknown, .created, .paymentProcessing, .paid, .sending,
        .refunding, .finished, .failed, .expired, .refunded,
    ])
    func onrampWithNothingToFollowUpOnOffersNoProviderLink(status: OnrampTransactionStatus) {
        #expect(source(forOnramp: status) == nil)
    }

    // MARK: - Swap

    @Test
    func swapAwaitingVerificationReportsKYC() {
        #expect(source(forSwap: .verifying, createdAt: Date()) == .kyc)
    }

    @Test
    func pausedSwapReportsTheStatusBlock() {
        #expect(source(forSwap: .paused, createdAt: Date()) == .status)
    }

    @Test(arguments: [ExpressTransactionStatus.confirming, .exchanging, .sending])
    func swapStuckInProgressReportsALongTransaction(status: ExpressTransactionStatus) {
        #expect(source(forSwap: status, createdAt: longAgo) == .longTime)
    }

    /// A swap that has been waiting a while but never paid in is not late — it simply hasn't started.
    @Test(arguments: [ExpressTransactionStatus.waiting, .waitingTxHash, .exchangeTxSent])
    func swapWaitingForThePayInIsLongRunningOnlyOncePaid(status: ExpressTransactionStatus) {
        #expect(source(forSwap: status, createdAt: longAgo, payInHash: nil) == nil)
        #expect(source(forSwap: status, createdAt: longAgo, payInHash: "0xPayIn") == .longTime)
    }

    /// A swap waiting on verification is held up by the user, not running late, so it keeps sending them to
    /// verification however long it has been open.
    @Test
    func verificationOutlastsTheLongTransactionThreshold() {
        #expect(source(forSwap: .verifying, createdAt: longAgo) == .kyc)
    }

    @Test(arguments: [ExpressTransactionStatus.confirming, .exchanging, .sending])
    func aFreshSwapInProgressOffersNoProviderLink(status: ExpressTransactionStatus) {
        #expect(source(forSwap: status, createdAt: Date()) == nil)
    }

    @Test(arguments: [
        ExpressTransactionStatus.unknown, .preview, .created,
        .finished, .failed, .txFailed, .refunded, .expired,
    ])
    func aSettledSwapOffersNoProviderLink(status: ExpressTransactionStatus) {
        #expect(source(forSwap: status, createdAt: longAgo) == nil)
    }
}

// MARK: - Fixtures

private extension TransactionDetailsProviderNavigationSourceTests {
    func source(forOnramp status: OnrampTransactionStatus) -> TransactionDetailsProviderNavigationSource? {
        TransactionDetailsFactory.providerNavigationSource(for: .onramp(makeOnrampInfo(status: status)))
    }

    func source(
        forSwap status: ExpressTransactionStatus,
        createdAt: Date,
        payInHash: String? = "0xPayIn"
    ) -> TransactionDetailsProviderNavigationSource? {
        let info = makeExchangeInfo(status: status, createdAt: createdAt, payInHash: payInHash)
        return TransactionDetailsFactory.providerNavigationSource(for: .exchange(info))
    }

    func makeOnrampInfo(status: OnrampTransactionStatus) -> OnrampTransactionInfo {
        OnrampTransactionInfo(
            transaction: ExpressMergeTestDataFactory.onrampTransaction(
                txId: "tx",
                status: status,
                payOutAddress: "0xOut",
                payOutHash: nil,
                toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.ethereumToken),
                toAmount: 1,
                toActualAmount: 1,
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
            ),
            provider: nil,
            fiatCurrency: nil,
            cryptoCurrencies: [:]
        )
    }

    func makeExchangeInfo(
        status: ExpressTransactionStatus,
        createdAt: Date,
        payInHash: String?
    ) -> ExchangeTransactionInfo {
        let fromCurrency = ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.ethereumToken)
        let toCurrency = ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.bitcoinToken)

        return ExchangeTransactionInfo(
            transaction: ExpressMergeTestDataFactory.exchangeTransaction(
                txId: "tx",
                status: status,
                fromAddress: "0xFrom",
                payInAddress: "0xIn",
                payInHash: payInHash,
                payOutAddress: "0xOut",
                payOutHash: nil,
                fromCurrency: fromCurrency,
                fromAmount: 1,
                fromActualAmount: nil,
                toCurrency: toCurrency,
                toAmount: 1,
                toActualAmount: nil,
                refund: nil,
                createdAt: createdAt,
                updatedAt: createdAt
            ),
            provider: nil,
            cryptoCurrencies: [
                fromCurrency: ExpressMergeTestDataFactory.ethereumToken,
                toCurrency: ExpressMergeTestDataFactory.bitcoinToken,
            ]
        )
    }
}
