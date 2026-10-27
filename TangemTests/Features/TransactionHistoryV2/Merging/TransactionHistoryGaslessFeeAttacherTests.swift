//
//  TransactionHistoryGaslessFeeAttacherTests.swift
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

@Suite("TransactionHistoryGaslessFeeAttacher")
struct TransactionHistoryGaslessFeeAttacherTests {
    @Test("The relayer's fee lands on the row it paid for, which keeps its deal and stays folded")
    func theFeeLandsOnThePayingRow() throws {
        let info = TransactionHistoryExpressExtraInfo.exchange(makeExchangeInfo(txId: "deal"))
        let paid = try #require(Decimal(stringValue: "0.25"))
        let row = makeRow(hash: Self.hash, isFolded: true).withExpressExtraInfo(info)

        let rows = makeAttacher().attach([makeFee(hash: Self.hash, amount: paid)], to: [row])

        let paying = try #require(rows.singleElement)
        #expect(paying.fee.amount.value == paid)
        #expect(paying.historyExtraInfo == .express(info))
        #expect(paying.isFolded)
    }

    @Test("Several fee transfers of one transaction add up to a single fee")
    func feesOfOneTransactionAreSummed() throws {
        let rows = makeAttacher().attach(
            [makeFee(hash: Self.hash, amount: 1), makeFee(hash: Self.hash, amount: 2)],
            to: [makeRow(hash: Self.hash)]
        )

        #expect(try #require(rows.singleElement).fee.amount.value == 3)
    }

    @Test("Of several rows of one transaction the outgoing one pays, even when it comes later")
    func theOutgoingRowPays() {
        let incoming = makeRow(hash: Self.hash, index: 0, isOutgoing: false)
        let outgoing = makeRow(hash: Self.hash, index: 1, isOutgoing: true)

        let rows = makeAttacher().attach([makeFee(hash: Self.hash, amount: 1)], to: [incoming, outgoing])

        #expect(rows.map(\.fee.amount.value) == [0, 1])
    }

    @Test("A fee that pays for no row is kept as a row of its own")
    func anUnmatchedFeeStaysARow() {
        let row = makeRow(hash: Self.hash)
        let fee = makeFee(hash: "0xOther", amount: 1)

        let rows = makeAttacher().attach([fee], to: [row])

        #expect(rows == [row, fee])
    }
}

// MARK: - Fixtures

private extension TransactionHistoryGaslessFeeAttacherTests {
    static let hash = "0xHash"
    static let owner = "0xowner"
    static let pool = "0xpool"
    static let collector = "0xcollector"

    func makeAttacher() -> TransactionHistoryGaslessFeeAttacher {
        TransactionHistoryGaslessFeeAttacher(currentToken: ExpressMergeTestDataFactory.ethereumToken)
    }

    func makeRow(hash: String, index: Int = 0, isOutgoing: Bool = true, isFolded: Bool = false) -> TransactionRecord {
        TransactionRecord(
            hash: hash,
            index: index,
            source: .single(.init(address: isOutgoing ? Self.owner : Self.pool, amount: 1)),
            destination: .single(.init(address: .user(isOutgoing ? Self.pool : Self.owner), amount: 1)),
            fee: ExpressMergeTestDataFactory.ethereumToken.zeroFee,
            status: .confirmed,
            isOutgoing: isOutgoing,
            type: .transfer,
            date: ExpressMergeTestDataFactory.baseDate,
            tokenTransfers: [],
            isFolded: isFolded,
            nonce: nil
        )
    }

    func makeFee(hash: String, amount: Decimal) -> TransactionRecord {
        TransactionRecord(
            hash: hash,
            index: 9,
            source: .single(.init(address: Self.owner, amount: amount)),
            destination: .single(.init(address: .user(Self.collector), amount: amount)),
            fee: ExpressMergeTestDataFactory.ethereumToken.zeroFee,
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: ExpressMergeTestDataFactory.baseDate,
            tokenTransfers: [],
            nonce: nil
        )
    }

    func makeExchangeInfo(txId: String) -> ExchangeTransactionInfo {
        ExchangeTransactionInfo(
            transaction: ExpressMergeTestDataFactory.exchangeTransaction(
                txId: txId,
                status: .finished,
                fromAddress: Self.owner,
                payInAddress: Self.pool,
                payInHash: Self.hash,
                payOutAddress: Self.collector,
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
