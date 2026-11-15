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
@testable import BlockchainSdk

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

    @Test(
        "A stored rate type is read back, a missing or unknown one as float",
        arguments: [(String?.none, ExpressProviderRateType.float), ("fixed", .fixed), ("some-future-rate", .float)]
    )
    func storedRateTypeIsReadBack(storedRateType: String?, expected: ExpressProviderRateType) throws {
        let records = TransactionHistoryRecordsMapper.mapToTransactionHistoryExtraInfo([
            makeExchangeIndexInfo(makeExchangeTransaction(txId: "swap"), storedRateType: storedRateType),
        ])

        let extraInfo = try #require(records.singleElement)
        guard case .express(.exchange(let info)) = extraInfo else {
            Issue.record("Expected Express exchange info, got \(extraInfo)")
            return
        }

        #expect(info.transaction.rateType == expected)
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

    @Test("A joint operation row is read back as joint operation info, the operation intact")
    func jointOperationRowIsReadAsJointOperationInfo() throws {
        let item = JointOperationHistoryTestDataFactory.coinItem(id: "joint", status: .executed)

        let records = TransactionHistoryRecordsMapper.mapToTransactionHistoryExtraInfo([
            makeJointOperationIndexInfo(TransactionHistoryRecordsMapper.mapToJointOperationRecord(item)),
        ])

        let extraInfo = try #require(records.singleElement)
        guard case .jointOperation(let info) = extraInfo else {
            Issue.record("Expected joint operation info, got \(extraInfo)")
            return
        }

        #expect(info.item == item)
        #expect(extraInfo.groupingId == "joint")
    }

    @Test("A token joint operation keeps its calldata through the record")
    func tokenJointOperationKeepsCalldata() throws {
        let item = try JointOperationHistoryTestDataFactory.tokenItem(id: "joint", status: .cancelled)

        let records = TransactionHistoryRecordsMapper.mapToTransactionHistoryExtraInfo([
            makeJointOperationIndexInfo(TransactionHistoryRecordsMapper.mapToJointOperationRecord(item)),
        ])

        #expect(records == [.jointOperation(JointOperationHistoryInfo(item: item))])
    }

    @Test("Stored values this version does not know are read as unknown")
    func unknownStoredValuesAreReadAsUnknown() throws {
        let item = JointOperationHistoryTestDataFactory.coinItem(id: "joint", status: .executed)
        let record = TransactionHistoryRecordsMapper.mapToJointOperationRecord(item)
        let futureRecord = JointOperationRecord(
            id: record.id,
            cryptoAccountID: record.cryptoAccountID,
            safeAddress: record.safeAddress,
            chainID: record.chainID,
            status: "rejectedByRelayer",
            initiator: record.initiator,
            to: record.to,
            value: record.value,
            data: record.data,
            operation: record.operation,
            safeTxGas: record.safeTxGas,
            baseGas: record.baseGas,
            gasPrice: record.gasPrice,
            gasToken: record.gasToken,
            refundReceiver: record.refundReceiver,
            nonce: record.nonce,
            threshold: record.threshold,
            txHash: record.txHash,
            cancelReason: "expired",
            signatures: [JointOperationRecord.Signature(address: "0xmember", state: "abstained", at: "2026-09-08T09:20:37.000Z")],
            createdAt: record.createdAt,
            finishedAt: record.finishedAt
        )

        let records = TransactionHistoryRecordsMapper.mapToTransactionHistoryExtraInfo([makeJointOperationIndexInfo(futureRecord)])

        let operation = try #require(records.singleElement?.jointOperationItem).operation
        #expect(operation.status == .unknown)
        #expect(operation.cancelReason == nil)
        #expect(operation.signatures.map(\.state) == [.unknown])
    }

    @Test("A joint operation row whose operation is missing is skipped")
    func jointOperationRowWithoutOperationIsSkipped() {
        let records = TransactionHistoryRecordsMapper.mapToTransactionHistoryExtraInfo([
            makeIndexInfo(
                entityType: TransactionHistoryIndexRecord.Values.EntityType.jointOperation,
                entityID: "joint",
                exchange: nil,
                onramp: nil
            ),
        ])

        #expect(records.isEmpty)
    }

    @Test("A coin joint operation is indexed under the Safe, its network and the coin contract")
    func coinJointOperationIndexRecord() throws {
        let item = JointOperationHistoryTestDataFactory.coinItem(id: "joint")

        let indexRecord = try #require(TransactionHistoryRecordsMapper.mapToTransactionHistoryIndexRecord(item))

        #expect(indexRecord.entityType == TransactionHistoryIndexRecord.Values.EntityType.jointOperation)
        #expect(indexRecord.entityID == "joint")
        #expect(indexRecord.address == JointOperationHistoryTestDataFactory.safeAddress)
        #expect(indexRecord.network == Blockchain.base(testnet: false).networkId)
        #expect(indexRecord.contract == ExpressConstants.coinContractAddress)
        #expect(indexRecord.dateTime == JointOperationHistoryTestDataFactory.createdAt)
    }

    @Test("A token joint operation is indexed under the token contract, lowercased")
    func tokenJointOperationIndexRecord() throws {
        let item = try JointOperationHistoryTestDataFactory.tokenItem(id: "joint")

        let indexRecord = try #require(TransactionHistoryRecordsMapper.mapToTransactionHistoryIndexRecord(item))

        #expect(indexRecord.contract == JointOperationHistoryTestDataFactory.checksummedTokenContract.lowercased())
    }

    @Test("A joint operation on a chain joint accounts do not support gets no index record")
    func unsupportedChainJointOperationHasNoIndexRecord() {
        let item = JointOperationHistoryTestDataFactory.coinItem(chainId: JointOperationHistoryTestDataFactory.unsupportedChainId)

        #expect(TransactionHistoryRecordsMapper.mapToTransactionHistoryIndexRecord(item) == nil)
    }

    @Test("A joint operation this version cannot read gets no index record")
    func unreadableJointOperationHasNoIndexRecord() {
        let item = JointOperationHistoryTestDataFactory.delegateCallItem()

        #expect(TransactionHistoryRecordsMapper.mapToTransactionHistoryIndexRecord(item) == nil)
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
        makeExchangeIndexInfo(transaction, record: TransactionHistoryRecordsMapper.mapToExpressExchangeTransactionRecord(transaction))
    }

    func makeExchangeIndexInfo(_ transaction: ExchangeTransaction, storedRateType: String?) -> TransactionHistoryIndexInfoRecord {
        let record = TransactionHistoryRecordsMapper.mapToExpressExchangeTransactionRecord(transaction)
        return makeExchangeIndexInfo(transaction, record: record.withRateType(storedRateType))
    }

    func makeExchangeIndexInfo(_ transaction: ExchangeTransaction, record: ExpressExchangeTransactionRecord) -> TransactionHistoryIndexInfoRecord {
        makeIndexInfo(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.expressExchange,
            entityID: transaction.txId,
            exchange: .init(
                transaction: record,
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

    func makeJointOperationIndexInfo(_ record: JointOperationRecord) -> TransactionHistoryIndexInfoRecord {
        makeIndexInfo(
            entityType: TransactionHistoryIndexRecord.Values.EntityType.jointOperation,
            entityID: record.id,
            exchange: nil,
            onramp: nil,
            jointOperation: record
        )
    }

    func makeIndexInfo(
        entityType: String,
        entityID: String,
        exchange: TransactionHistoryIndexInfoRecord.ExchangeRecords?,
        onramp: TransactionHistoryIndexInfoRecord.OnrampRecords?,
        jointOperation: JointOperationRecord? = nil
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
            onrampTransaction: onramp,
            jointOperation: jointOperation
        )
    }
}

// MARK: - Convenience extensions

private extension TransactionHistoryExtraInfo {
    var jointOperationItem: JointOperationHistoryItem? {
        guard case .jointOperation(let info) = self else {
            return nil
        }

        return info.item
    }
}

private extension ExpressExchangeTransactionRecord {
    func withRateType(_ rateType: String?) -> ExpressExchangeTransactionRecord {
        ExpressExchangeTransactionRecord(
            id: id,
            providerID: providerID,
            fromAddress: fromAddress,
            payInAddress: payInAddress,
            payInExtraId: payInExtraId,
            payOutAddress: payOutAddress,
            status: status,
            rateType: rateType,
            externalTxID: externalTxID,
            externalTxURL: externalTxURL,
            payInHash: payInHash,
            payOutHash: payOutHash,
            fromNetwork: fromNetwork,
            fromContract: fromContract,
            fromAmount: fromAmount,
            fromDecimals: fromDecimals,
            fromActualAmount: fromActualAmount,
            toNetwork: toNetwork,
            toContract: toContract,
            toAmount: toAmount,
            toDecimals: toDecimals,
            toActualAmount: toActualAmount,
            refundAddress: refundAddress,
            refundExtraId: refundExtraId,
            refundNetwork: refundNetwork,
            refundContractAddress: refundContractAddress,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
