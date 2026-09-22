//
//  TransactionHistoryTransferCollapser.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation

/// Folds the transfers of one on-chain transaction back into the single history row they came from.
///
/// A swap reaches the history as several records: the provider takes the deposit in one transfer, the router
/// pays out in another, and a contract can add transfers of its own on top — so one operation is drawn as two
/// or three rows. Each transaction is folded into one row carrying what the wallet actually gained or lost and
/// a single fee.
struct TransactionHistoryTransferCollapser {
    private let smartContractMethodMapper: SmartContractMethodMapper
    private let walletModelAddresses: Set<String>
    private let isEvm: Bool

    init(
        walletModelAddresses: Set<String>,
        isEvm: Bool,
        smartContractMethodMapper: SmartContractMethodMapper
    ) {
        self.walletModelAddresses = walletModelAddresses
        self.isEvm = isEvm
        self.smartContractMethodMapper = smartContractMethodMapper
    }

    func collapse(_ records: [TransactionRecord]) -> [TransactionRecord] {
        var groupsInOrder: [GroupKey] = []
        var groupedRecords: [GroupKey: [TransactionRecord]] = [:]

        for record in records {
            let key = GroupKey(hash: record.hash, expressTransactionId: record.expressExtraInfo?.txId)

            if groupedRecords[key] == nil {
                groupsInOrder.append(key)
            }

            groupedRecords[key, default: []].append(record)
        }

        return groupsInOrder.flatMap { collapsed(groupedRecords[$0] ?? []) }
    }
}

// MARK: - Collapsing a single group

private extension TransactionHistoryTransferCollapser {
    func collapsed(_ group: [TransactionRecord]) -> [TransactionRecord] {
        guard group.count > 1, let anchor = group.min(by: \.index) else {
            return group
        }

        // Gasless is out of scope by the acceptance criteria: its fee arrives as a record of its own that the
        // history is meant to show separately, and folding the transaction would swallow it.
        guard !isGasless(anchor) else {
            return group
        }

        let movingTransfers = group
            .map { (record: $0, delta: delta(of: $0)) }
            .filter { !$0.delta.isZero }

        let movingRecords = movingTransfers.map(\.record)

        guard let ownAddress = ownAddress(in: movingRecords) else {
            return group
        }

        let totalDelta = movingTransfers.reduce(Decimal.zero) { $0 + $1.delta }

        return [
            makeCollapsedRecord(
                anchor: anchor,
                movingTransfers: movingRecords,
                ownAddress: ownAddress,
                delta: totalDelta,
                fee: fee(of: group, anchor: anchor)
            ),
        ]
    }

    func delta(of record: TransactionRecord) -> Decimal {
        let received = record.destination.destinations
            .filter { isOwn($0.address.string) }
            .reduce(Decimal.zero) { $0 + $1.amount }

        let sent = record.source.sources
            .filter { isOwn($0.address) }
            .reduce(Decimal.zero) { $0 + $1.amount }

        return received - sent
    }

    func makeCollapsedRecord(
        anchor: TransactionRecord,
        movingTransfers: [TransactionRecord],
        ownAddress: String,
        delta: Decimal,
        fee: Fee
    ) -> TransactionRecord {
        let isOutgoing = delta < 0

        let source: TransactionRecord.SourceType
        let destination: TransactionRecord.DestinationType

        if isOutgoing {
            source = .single(.init(address: ownAddress, amount: abs(delta)))
            destination = .from(counterpartyDestinations(of: movingTransfers).nilIfEmpty ?? anchor.destination.destinations)
        } else {
            source = .from(counterpartySources(of: movingTransfers).nilIfEmpty ?? anchor.source.sources)
            destination = .single(.init(address: .user(ownAddress), amount: delta))
        }

        return TransactionRecord(
            hash: anchor.hash,
            index: anchor.index,
            source: source,
            destination: destination,
            fee: fee,
            status: anchor.status,
            isOutgoing: isOutgoing,
            type: anchor.type,
            date: anchor.date,
            tokenTransfers: anchor.tokenTransfers,
            isFromYieldContract: anchor.isFromYieldContract,
            nonce: anchor.nonce,
            extraInfo: anchor.expressExtraInfo
        )
    }

    func fee(of group: [TransactionRecord], anchor: TransactionRecord) -> Fee {
        let distinctFees = group.map(\.fee).unique()

        if distinctFees.count > 1 {
            TransactionHistoryLogger.warning(
                "Transaction \(anchor.hash) reports \(distinctFees.count) different fees across its \(group.count) transfers, taking the one of index \(anchor.index)"
            )
        }

        return anchor.fee
    }
}

// MARK: - Addresses

private extension TransactionHistoryTransferCollapser {
    func isOwn(_ address: String) -> Bool {
        walletModelAddresses.contains(TransactionHistoryAddressNormalizer.normalize(address, isEvm: isEvm))
    }

    func ownAddress(in records: [TransactionRecord]) -> String? {
        let participating = records.lazy.flatMap { record in
            record.source.sources.map(\.address) + record.destination.destinations.map(\.address.string)
        }

        return participating.first(where: isOwn)
    }

    func counterpartyDestinations(of records: [TransactionRecord]) -> [TransactionRecord.Destination] {
        var amountsByAddress: [String: Decimal] = [:]
        var addressesInOrder: [(key: String, address: TransactionRecord.Destination.Address)] = []

        for destination in records.flatMap({ $0.destination.destinations }) where !isOwn(destination.address.string) {
            let key = TransactionHistoryAddressNormalizer.normalize(destination.address.string, isEvm: isEvm)

            if amountsByAddress[key] == nil {
                addressesInOrder.append((key, destination.address))
            }

            amountsByAddress[key, default: 0] += destination.amount
        }

        return addressesInOrder.map { .init(address: $0.address, amount: amountsByAddress[$0.key] ?? 0) }
    }

    func counterpartySources(of records: [TransactionRecord]) -> [TransactionRecord.Source] {
        var amountsByAddress: [String: Decimal] = [:]
        var addressesInOrder: [(key: String, address: String)] = []

        for source in records.flatMap({ $0.source.sources }) where !isOwn(source.address) {
            let key = TransactionHistoryAddressNormalizer.normalize(source.address, isEvm: isEvm)

            if amountsByAddress[key] == nil {
                addressesInOrder.append((key, source.address))
            }

            amountsByAddress[key, default: 0] += source.amount
        }

        return addressesInOrder.map { .init(address: $0.address, amount: amountsByAddress[$0.key] ?? 0) }
    }
}

// MARK: - Gasless

private extension TransactionHistoryTransferCollapser {
    func isGasless(_ record: TransactionRecord) -> Bool {
        switch record.type {
        case .contractMethodIdentifier(let id):
            return smartContractMethodMapper.getName(for: id) == Constants.gaslessTransactionMethodName
        case .contractMethodName(let name):
            return name == Constants.gaslessTransactionMethodName
        case .transfer, .staking, .approve:
            return false
        }
    }
}

// MARK: - Auxiliary types

private extension TransactionHistoryTransferCollapser {
    struct GroupKey: Hashable {
        let hash: String
        let expressTransactionId: String?
    }
}

// MARK: - Constants

private extension TransactionHistoryTransferCollapser {
    enum Constants {
        static let gaslessTransactionMethodName = "gaslessTransaction"
    }
}
