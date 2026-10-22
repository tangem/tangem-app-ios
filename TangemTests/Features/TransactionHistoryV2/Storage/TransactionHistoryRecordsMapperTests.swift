//
//  TransactionHistoryRecordsMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemAppDatabase
@testable import Tangem
@testable import TangemExpress

@Suite("TransactionHistoryRecordsMapper")
struct TransactionHistoryRecordsMapperTests {
    @Test("An exchange index row is read back as Express exchange info")
    func exchangeRowIsReadAsExpressExchangeInfo() throws {
        let records = TransactionHistoryRecordsMapper.mapToTransactionHistoryExtraInfo([
            makeExchangeIndexInfo(makeExchangeTransaction(txId: "swap")),
        ])

        let extraInfo = try #require(records.singleElement)
        guard case .express(.exchange(let info)) = extraInfo else {
            Issue.record("Expected Express exchange info, got \(extraInfo)")
            return
        }

        #expect(info.transaction.txId == "swap")
        #expect(extraInfo.groupingId == "swap")
    }

    @Test("An onramp index row is read back as Express onramp info")
    func onrampRowIsReadAsExpressOnrampInfo() throws {
        let records = TransactionHistoryRecordsMapper.mapToTransactionHistoryExtraInfo([
            makeOnrampIndexInfo(makeOnrampTransaction(txId: "onramp")),
        ])

        let extraInfo = try #require(records.singleElement)
        guard case .express(.onramp(let info)) = extraInfo else {
            Issue.record("Expected Express onramp info, got \(extraInfo)")
            return
        }

        #expect(info.transaction.txId == "onramp")
        #expect(extraInfo.groupingId == "onramp")
    }

    @Test("A row of an unknown entity type is skipped and the others are kept")
    func unknownEntityTypeIsSkipped() {
        let records = TransactionHistoryRecordsMapper.mapToTransactionHistoryExtraInfo([
            makeIndexInfo(entityType: "staking", entityID: "stake", exchange: nil, onramp: nil),
            makeExchangeIndexInfo(makeExchangeTransaction(txId: "swap")),
        ])

        #expect(records.map(\.groupingId) == ["swap"])
    }

    @Test("An exchange row whose transaction is missing is skipped")
    func exchangeRowWithoutTransactionIsSkipped() {
        let records = TransactionHistoryRecordsMapper.mapToTransactionHistoryExtraInfo([
            makeIndexInfo(
                entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
                entityID: "swap",
                exchange: nil,
                onramp: nil
            ),
        ])

        #expect(records.isEmpty)
    }
}

// MARK: - Fixtures

private extension TransactionHistoryRecordsMapperTests {
    static let owner = "0xowner"

    func makeExchangeTransaction(txId: String) -> ExchangeTransaction {
        ExpressMergeTestDataFactory.exchangeTransaction(
            txId: txId,
            status: .finished,
            fromAddress: Self.owner,
            payInAddress: "0xpayin",
            payInHash: "0xHash",
            payOutAddress: "0xpayout",
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
        )
    }

    func makeOnrampTransaction(txId: String) -> OnrampTransaction {
        ExpressMergeTestDataFactory.onrampTransaction(
            txId: txId,
            status: .finished,
            payOutAddress: Self.owner,
            payOutHash: "0xHash",
            toCurrency: ExpressMergeTestDataFactory.matchingCurrency(for: ExpressMergeTestDataFactory.ethereumToken),
            toAmount: 1,
            toActualAmount: 1,
            createdAt: ExpressMergeTestDataFactory.baseDate,
            updatedAt: ExpressMergeTestDataFactory.baseDate
        )
    }

    func makeExchangeIndexInfo(_ transaction: ExchangeTransaction) -> TransactionHistoryIndexInfoRecord {
        makeIndexInfo(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: transaction.txId,
            exchange: .init(
                transaction: TransactionHistoryRecordsMapper.mapToExpressExchangeTransactionRecord(transaction),
                provider: nil,
                fromCryptoCurrency: nil,
                toCryptoCurrency: nil,
                refundCryptoCurrency: nil
            ),
            onramp: nil
        )
    }

    func makeOnrampIndexInfo(_ transaction: OnrampTransaction) -> TransactionHistoryIndexInfoRecord {
        makeIndexInfo(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressOnramp,
            entityID: transaction.txId,
            exchange: nil,
            onramp: .init(
                transaction: TransactionHistoryRecordsMapper.mapToExpressOnrampTransactionRecord(transaction),
                provider: nil,
                fiatCurrency: nil,
                cryptoCurrency: nil
            )
        )
    }

    func makeIndexInfo(
        entityType: String,
        entityID: String,
        exchange: TransactionHistoryIndexInfoRecord.ExchangeRecords?,
        onramp: TransactionHistoryIndexInfoRecord.OnrampRecords?
    ) -> TransactionHistoryIndexInfoRecord {
        TransactionHistoryIndexInfoRecord(
            indexRecord: TransactionHistoryIndexRecord(
                entityType: entityType,
                entityID: entityID,
                address: Self.owner,
                network: "ethereum",
                contract: "0",
                dateTime: ExpressMergeTestDataFactory.baseDate
            ),
            exchangeTransaction: exchange,
            onrampTransaction: onramp
        )
    }
}
