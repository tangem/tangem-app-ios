//
//  UserDefaultsTransactionHistoryRecordsStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemAppDatabase
import TangemFoundation

// [REDACTED_TODO_COMMENT]
actor UserDefaultsTransactionHistoryRecordsStorage<Record: TransactionHistoryRecord> {
    /// - Note: Despite the name of the type, this inner storage is not limited to BlockchainSDK. It's just a convenient UserDefaults wrapper.
    private let dataStorage: BlockchainDataStorage
    private let ownerAddress: String
    private let storageKey: String

    private lazy var recordsKeyedByTxId: [String: Record] = loadRecords()
    private var subscribersKeyedByCurrency: [ExpressCurrency: AsyncStream<[Record]>.MulticastSubscribers<UUID>] = [:]

    init(dataStorage: BlockchainDataStorage, ownerAddress: String) {
        self.dataStorage = dataStorage
        self.ownerAddress = ownerAddress
        storageKey = Self.makeStorageKey(ownerAddress: ownerAddress)
    }

    private static func makeStorageKey(ownerAddress: String) -> String {
        "TxHistoryRecords_\(Record.self)_\(ownerAddress)_v1"
    }

    private func loadRecords() -> [String: Record] {
        let databaseRecords: [DatabaseRecord]? = dataStorage.get(key: storageKey)

        return databaseRecords?
            .compactMap(\.asDomainEntity)
            .compactMap { $0 as? Record }
            .keyedLast(by: \.txId) ?? [:]
    }

    private func makeSnapshot() -> [Record] {
        recordsKeyedByTxId.values.sorted(by: \.updatedAt)
    }

    private func makeSnapshot(for currency: ExpressCurrency, using snapshot: [Record]? = nil) -> [Record] {
        let snapshot = snapshot ?? makeSnapshot()

        return snapshot.filter { $0.isRelatedTo(currency) }
    }

    private func storeSnapshot() {
        dataStorage.store(
            key: storageKey,
            value: makeSnapshot().compactMap { DatabaseRecord(from: $0, ownerAddress: ownerAddress) }
        )
    }

    private func notifySubscribers() {
        let snapshot = makeSnapshot()

        for (currency, subscribers) in subscribersKeyedByCurrency {
            subscribers.yield(makeSnapshot(for: currency, using: snapshot))
        }
    }
}

// MARK: - TransactionHistoryRecordsStorage protocol conformance

extension UserDefaultsTransactionHistoryRecordsStorage: TransactionHistoryRecordsStorage {
    nonisolated func recordsUpdates(for currency: ExpressCurrency) -> AsyncStream<[Record]> {
        .multicast(
            with: self,
            onSubscribe: { storage, id, continuation in
                storage.subscribersKeyedByCurrency[currency, default: .init()].subscribe(
                    id: id,
                    continuation: continuation,
                    currentValue: storage.makeSnapshot(for: currency)
                )
            },
            onUnsubscribe: { storage, id in
                storage.subscribersKeyedByCurrency[currency, default: .init()].unsubscribe(id: id)
            }
        )
    }

    func updateOrAppend(_ records: [Record]) throws {
        records.forEach { recordsKeyedByTxId[$0.txId] = $0 }
        storeSnapshot()
        notifySubscribers()
    }

    func clear() throws {
        recordsKeyedByTxId.removeAll()
        storeSnapshot()
        notifySubscribers()
    }
}

// MARK: - DTOs

private enum DatabaseRecord: Codable {
    case exchange(ExpressExchangeTransactionRecord)
    case onramp(ExpressOnrampTransactionRecord)

    init?(from record: TransactionHistoryRecord, ownerAddress: String) {
        switch record {
        case let record as ExchangeTransaction:
            self = .exchange(record.makeDatabaseRecord(ownerAddress: ownerAddress))
        case let record as OnrampTransaction:
            self = .onramp(record.makeDatabaseRecord(ownerAddress: ownerAddress))
        default:
            TransactionHistoryLogger.warning("Unable to persist a record of an unsupported type '\(type(of: record))'")
            return nil
        }
    }

    var asDomainEntity: TransactionHistoryRecord? {
        switch self {
        case .exchange(let record):
            return ExchangeTransaction(from: record)
        case .onramp(let record):
            return OnrampTransaction(from: record)
        }
    }
}

// MARK: - Filtering

private extension TransactionHistoryRecord {
    var expressCurrencies: [ExpressCurrency] {
        switch self {
        case let record as ExchangeTransaction:
            return record.expressCurrencies
        case let record as OnrampTransaction:
            return record.expressCurrencies
        default:
            TransactionHistoryLogger.warning("Unable to filter a record of an unsupported type '\(type(of: self))'")
            return []
        }
    }

    func isRelatedTo(_ currency: ExpressCurrency) -> Bool {
        expressCurrencies.contains { $0.matches(currency) }
    }
}

private extension ExpressCurrency {
    /// - Note: Contract addresses are compared case-insensitively, just like `BlockchainSdk.Token` equality does.
    func matches(_ other: ExpressCurrency) -> Bool {
        network == other.network && contractAddress.caseInsensitiveCompare(other.contractAddress) == .orderedSame
    }
}

// MARK: - Exchange records mapping

private extension ExchangeTransaction {
    init?(from databaseRecord: ExpressExchangeTransactionRecord) {
        guard
            let fromAmount = Decimal(stringValue: databaseRecord.fromAmount),
            let toAmount = Decimal(stringValue: databaseRecord.toAmount)
        else {
            TransactionHistoryLogger.warning("Unable to restore amounts of the stored exchange record '\(databaseRecord.id)'")
            return nil
        }

        self.init(
            txId: databaseRecord.id,
            providerId: databaseRecord.providerID,
            status: ExpressTransactionStatus(rawValue: databaseRecord.status) ?? .unknown,
            rateType: databaseRecord.rateType.flatMap(ExpressProviderRateType.init),
            externalTx: databaseRecord.externalTxInfo,
            fromAddress: databaseRecord.fromAddress,
            payIn: PayInInfo(
                address: databaseRecord.payInAddress,
                extraId: databaseRecord.payInExtraId,
                hash: databaseRecord.payInHash
            ),
            payOut: PayOutInfo(
                address: databaseRecord.payOutAddress,
                hash: databaseRecord.payOutHash
            ),
            refund: databaseRecord.refundInfo,
            from: ExpressHistoryAsset(
                currency: ExpressCurrency(
                    contractAddress: databaseRecord.fromContract,
                    network: databaseRecord.fromNetwork
                ),
                amount: fromAmount,
                actualAmount: Decimal(stringValue: databaseRecord.fromActualAmount),
                decimals: databaseRecord.fromDecimals
            ),
            to: ExpressHistoryAsset(
                currency: ExpressCurrency(
                    contractAddress: databaseRecord.toContract,
                    network: databaseRecord.toNetwork
                ),
                amount: toAmount,
                actualAmount: Decimal(stringValue: databaseRecord.toActualAmount),
                decimals: databaseRecord.toDecimals
            ),
            createdAt: databaseRecord.createdAt,
            updatedAt: databaseRecord.updatedAt,
            payTill: nil, // This field is not used in the tx history, so it is not persisted and always restored as `nil`
            averageDuration: nil // This field is not used in the tx history, so it is not persisted and always restored as `nil`
        )
    }

    func makeDatabaseRecord(ownerAddress: String) -> ExpressExchangeTransactionRecord {
        ExpressExchangeTransactionRecord(
            id: txId,
            ownerAddress: ownerAddress,
            providerID: providerId,
            fromAddress: fromAddress,
            payInAddress: payIn.address,
            payInExtraId: payIn.extraId,
            payOutAddress: payOut.address,
            status: status.rawValue,
            rateType: rateType?.rawValue,
            externalTxID: externalTx?.id,
            externalTxURL: externalTx?.url?.absoluteString,
            payInHash: payIn.hash,
            payOutHash: payOut.hash,
            fromNetwork: from.currency.network,
            fromContract: from.currency.contractAddress,
            fromAmount: from.amount.stringValue,
            fromDecimals: from.decimals,
            fromActualAmount: from.actualAmount?.stringValue,
            toNetwork: to.currency.network,
            toContract: to.currency.contractAddress,
            toAmount: to.amount.stringValue,
            toDecimals: to.decimals,
            toActualAmount: to.actualAmount?.stringValue,
            refundAddress: refund?.address,
            refundExtraId: refund?.extraId,
            refundNetwork: refund?.currency?.network,
            refundContractAddress: refund?.currency?.contractAddress,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private extension ExpressExchangeTransactionRecord {
    var externalTxInfo: ExternalTxInfo? {
        guard let externalTxID else {
            return nil
        }

        return ExternalTxInfo(id: externalTxID, url: externalTxURL.flatMap(URL.init(string:)))
    }

    var refundInfo: RefundInfo? {
        guard let refundAddress else {
            return nil
        }

        return RefundInfo(
            address: refundAddress,
            extraId: refundExtraId,
            currency: ExpressCurrency(network: refundNetwork, contractAddress: refundContractAddress)
        )
    }
}

// MARK: - Onramp records mapping

private extension OnrampTransaction {
    init?(from databaseRecord: ExpressOnrampTransactionRecord) {
        guard let fromAmount = Decimal(stringValue: databaseRecord.fromAmount) else {
            TransactionHistoryLogger.warning("Unable to restore amounts of the stored onramp record '\(databaseRecord.id)'")

            return nil
        }

        self.init(
            txId: databaseRecord.id,
            providerId: databaseRecord.providerID,
            status: OnrampTransactionStatus(rawValue: databaseRecord.status) ?? .unknown,
            failReason: databaseRecord.failReason,
            externalTx: databaseRecord.externalTxInfo,
            payOut: PayOutInfo(
                address: databaseRecord.payOutAddress,
                hash: databaseRecord.payOutHash
            ),
            from: OnrampHistoryFiatAsset(
                currencyCode: databaseRecord.fromCurrency,
                amount: fromAmount
            ),
            to: OnrampHistoryCryptoAsset(
                currency: ExpressCurrency(
                    contractAddress: databaseRecord.toContract,
                    network: databaseRecord.toNetwork
                ),
                amount: Decimal(stringValue: databaseRecord.toAmount),
                actualAmount: Decimal(stringValue: databaseRecord.toActualAmount),
                decimals: databaseRecord.toDecimals
            ),
            paymentMethod: databaseRecord.paymentMethod,
            countryCode: databaseRecord.countryCode,
            createdAt: databaseRecord.createdAt,
            updatedAt: databaseRecord.updatedAt
        )
    }

    func makeDatabaseRecord(ownerAddress: String) -> ExpressOnrampTransactionRecord {
        ExpressOnrampTransactionRecord(
            id: txId,
            ownerAddress: ownerAddress,
            providerID: providerId,
            payOutAddress: payOut.address,
            status: status.rawValue,
            externalTxID: externalTx?.id,
            externalTxURL: externalTx?.url?.absoluteString,
            payOutHash: payOut.hash,
            fromCurrency: from.currencyCode,
            fromAmount: from.amount.stringValue,
            toNetwork: to.currency.network,
            toContract: to.currency.contractAddress,
            toAmount: to.amount?.stringValue,
            toDecimals: to.decimals,
            toActualAmount: to.actualAmount?.stringValue,
            failReason: failReason,
            paymentMethod: paymentMethod,
            countryCode: countryCode,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private extension ExpressOnrampTransactionRecord {
    var externalTxInfo: ExternalTxInfo? {
        guard let externalTxID else {
            return nil
        }

        return ExternalTxInfo(id: externalTxID, url: externalTxURL.flatMap(URL.init(string:)))
    }
}
