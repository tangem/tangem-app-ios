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
        isIncoming: Bool = false
    ) -> PendingTransactionRecord {
        PendingTransactionRecord(
            hash: hash,
            source: transaction.sourceAddress,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            fee: transaction.fee,
            date: date,
            isIncoming: isIncoming,
            transactionType: .transfer,
            transactionParams: transaction.params
        )
    }

    func mapToPendingTransactionRecord(
        stakeKitTransaction: StakeKitTransaction,
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
            amount: stakeKitTransaction.amount,
            fee: stakeKitTransaction.fee,
            date: date,
            isIncoming: isIncoming,
            transactionType: .stake(validator: stakeKitTransaction.params.validator),
            transactionParams: stakeKitTransaction.params
        )
    }

    func mapToPendingTransactionRecord(
        _ pendingTransaction: PendingTransaction,
        blockchain: Blockchain
    ) -> PendingTransactionRecord {
        PendingTransactionRecord(
            hash: pendingTransaction.hash,
            source: pendingTransaction.source,
            destination: pendingTransaction.destination,
            amount: Amount(with: blockchain, value: pendingTransaction.value),
            fee: Fee(Amount(with: blockchain, value: pendingTransaction.fee ?? 0)),
            date: pendingTransaction.date,
            isIncoming: pendingTransaction.isIncoming,
            transactionType: .transfer,
            transactionParams: pendingTransaction.transactionParams
        )
    }

    func mapPendingTransactionRecord(record transaction: TransactionRecord, blockchain: Blockchain, address: String) throws -> PendingTransactionRecord {
        let isIncoming = !transaction.isOutgoing
        let outs = transaction.destination.destinations
        let destination = outs.first(where: { $0.address.string != address })?.address.string ?? .unknown

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
        case .contractMethodIdentifier, .contractMethodName: .operation
        case .staking(_, let validator): .stake(validator: validator)
        }

        return PendingTransactionRecord(
            hash: transaction.hash,
            source: isIncoming ? destination : address,
            destination: isIncoming ? address : destination,
            amount: .init(with: blockchain, type: .coin, value: value),
            fee: transaction.fee,
            date: transaction.date ?? Date(),
            isIncoming: isIncoming,
            transactionType: type
        )
    }
}
