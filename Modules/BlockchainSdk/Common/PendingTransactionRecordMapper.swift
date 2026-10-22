//
//  PendingTransactionRecordMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PendingTransactionRecordMapper {
    func makeDummy(blockchain: Blockchain) -> PendingTransactionRecord {
        PendingTransactionRecord(
            hash: .unknown,
            source: .unknown,
            destination: .unknown,
            amount: .zeroCoin(for: blockchain),
            fee: Fee(.zeroCoin(for: blockchain)),
            date: Date(),
            isIncoming: false,
            transactionType: .transfer,
            transactionParams: nil
        )
    }

    func mapToPendingTransactionRecord(
        transaction: Transaction,
        hash: String,
        date: Date = Date(),
        isIncoming: Bool = false,
        networkProviderType: NetworkProviderType? = nil
    ) -> PendingTransactionRecord {
        PendingTransactionRecord(
            hash: hash,
            source: transaction.sourceAddress,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            fee: transaction.fee,
            date: date,
            isIncoming: isIncoming,
            networkProviderType: networkProviderType,
            transactionType: .transfer,
            transactionParams: transaction.params
        )
    }

    func mapToPendingTransactionRecord(
        stakingTransaction: any StakingTransaction,
        source: String,
        destination: String = .unknown,
        hash: String,
        date: Date = Date(),
        isIncoming: Bool = false
    ) -> PendingTransactionRecord {
        PendingTransactionRecord(
            hash: hash,
            source: source,
            destination: destination,
            amount: stakingTransaction.amount,
            fee: stakingTransaction.fee,
            date: date,
            isIncoming: isIncoming,
            transactionType: .stake(target: stakingTransaction.target),
            transactionParams: nil
        )
    }

    func mapToPendingTransactionRecord(record transaction: TransactionRecord, blockchain: Blockchain, address: String) -> PendingTransactionRecord {
        let isIncoming = !transaction.isOutgoing
        let outs = transaction.destination.destinations
        let source: String = {
            if transaction.isOutgoing {
                return address
            }

            return transaction.source.sources.first(where: { $0.address != address })?.address ?? .unknown
        }()

        let destination: String = {
            if isIncoming {
                return address
            }

            return outs.first(where: { $0.address.string != address })?.address.string ?? .unknown
        }()

        let value: Decimal = {
            if isIncoming {
                // All outs which was sent only to `wallet` address
                return outs.filter { $0.address.string == address }.reduce(0) { $0 + $1.amount }
            }

            // All outs which was sent only to `other` addresses
            return outs.filter { $0.address.string != address }.reduce(0) { $0 + $1.amount }
        }()

        let type: PendingTransactionRecord.TransactionType = switch transaction.type {
        case .transfer: .transfer
        case .contractMethodIdentifier, .contractMethodName, .approve: .operation
        case .staking(_, let target): .stake(target: target)
        }

        return PendingTransactionRecord(
            hash: transaction.hash,
            source: source,
            destination: destination,
            amount: .init(with: blockchain, type: .coin, value: value),
            fee: transaction.fee,
            date: transaction.date ?? Date(),
            isIncoming: isIncoming,
            transactionType: type
        )
    }
}
