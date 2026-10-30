//
//  TransactionRecordHistoryExtraInfoTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

@Suite("TransactionRecord history extra info")
struct TransactionRecordHistoryExtraInfoTests {
    @Test("A record without extra info reads as nil through both projections")
    func plainRecordHasNoInfo() {
        let record = makeRecord()

        #expect(record.historyExtraInfo == nil)
        #expect(record.expressExtraInfo == nil)
    }

    @Test("Express info is read back through both projections and groups the row by its deal")
    func expressInfoIsProjected() {
        let info = TransactionHistoryExpressExtraInfo.exchange(makeExchangeInfo(txId: "deal"))

        let record = makeRecord().withExpressExtraInfo(info)

        #expect(record.historyExtraInfo == .express(info))
        #expect(record.expressExtraInfo == info)
        #expect(record.historyExtraInfo?.groupingId == "deal")
    }

    @Test("Copying a record with new info keeps it folded")
    func withHistoryExtraInfoKeepsIsFolded() {
        let folded = makeRecord(isFolded: true)
        let info = TransactionHistoryExtraInfo.express(.exchange(makeExchangeInfo(txId: "deal")))

        let enriched = folded.withHistoryExtraInfo(info)

        #expect(enriched.isFolded)
        #expect(enriched.historyExtraInfo == info)
        #expect(enriched.hash == folded.hash)
        #expect(enriched.index == folded.index)
    }

    @Test("A synthetic swap row carries its deal as Express info")
    func syntheticSwapRowCarriesExpressInfo() {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: token,
            ownerAddress: Self.owner,
            feeTokenItem: token
        )
        let exchange = ExpressMergeTestDataFactory.exchangeTransaction(
            txId: "swap",
            status: .waiting,
            fromAddress: Self.owner,
            payInAddress: Self.payIn,
            payInHash: nil,
            payOutAddress: Self.payOut,
            payOutHash: nil,
            fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            fromAmount: 1,
            fromActualAmount: nil,
            toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
            toAmount: 1,
            toActualAmount: nil,
            refund: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let record = factory.makeSyntheticTransaction(from: exchange)

        #expect(record.exchangeInfo?.transaction.txId == "swap")
        #expect(record.historyExtraInfo?.groupingId == "swap")
    }

    @Test("A synthetic onramp row carries its deal as Express info")
    func syntheticOnrampRowCarriesExpressInfo() {
        let token = ExpressMergeTestDataFactory.ethereumToken
        let factory = ExpressMergeTestDataFactory.makeFactory(
            currentToken: token,
            ownerAddress: Self.owner,
            feeTokenItem: token
        )
        let onramp = ExpressMergeTestDataFactory.onrampTransaction(
            txId: "onramp",
            status: .sending,
            payOutAddress: Self.owner,
            payOutHash: nil,
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: token),
            toAmount: 1,
            toActualAmount: nil,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )

        let record = factory.makeSyntheticTransaction(from: onramp)

        #expect(record.onrampInfo?.transaction.txId == "onramp")
        #expect(record.historyExtraInfo?.groupingId == "onramp")
    }
}

// MARK: - Fixtures

private extension TransactionRecordHistoryExtraInfoTests {
    static let owner = "0xowner"
    static let payIn = "0xpayin"
    static let payOut = "0xpayout"

    func makeRecord(isFolded: Bool = false) -> TransactionRecord {
        TransactionRecord(
            hash: "0xHash",
            index: 0,
            source: .single(.init(address: Self.owner, amount: 1)),
            destination: .single(.init(address: .user(Self.payIn), amount: 1)),
            fee: ExpressMergeTestDataFactory.ethereumToken.zeroFee,
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: ExpressMergeTestDataFactory.baseDate,
            tokenTransfers: [],
            isFolded: isFolded,
            nonce: nil
        )
    }

    func makeExchangeInfo(txId: String) -> ExchangeTransactionInfo {
        ExchangeTransactionInfo(
            transaction: ExpressMergeTestDataFactory.exchangeTransaction(
                txId: txId,
                status: .finished,
                fromAddress: Self.owner,
                payInAddress: Self.payIn,
                payInHash: "0xHash",
                payOutAddress: Self.payOut,
                payOutHash: nil,
                fromCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.ethereumToken),
                fromAmount: 1,
                fromActualAmount: nil,
                toCurrency: ExpressMergeTestDataFactory.unrelatedCurrency,
                toAmount: 1,
                toActualAmount: nil,
                refund: nil,
                createdAt: ExpressMergeTestDataFactory.baseDate,
                updatedAt: ExpressMergeTestDataFactory.baseDate
            ),
            provider: nil,
            cryptoCurrencies: [:]
        )
    }
}
