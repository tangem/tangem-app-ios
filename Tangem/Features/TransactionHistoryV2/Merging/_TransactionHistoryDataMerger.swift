//
//  _TransactionHistoryDataMerger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation

// [REDACTED_TODO_COMMENT]
struct _TransactionHistoryDataMerger {
    private let ownerAddress: String
    private let currentToken: TokenItem
    private let feeTokenItem: TokenItem

    private static let activeExchangeTransactionStatuses: Set<ExpressTransactionStatus> = [
        .preview,
        .created,
        .unknown,
        .exchangeTxSent,
        .waiting,
        .waitingTxHash,
        .confirming,
        .exchanging,
        .sending,
        .verifying,
        .failed,
    ]

    private static let activeOnrampTransactionStatuses: Set<OnrampTransactionStatus> = [
        .created,
        .waitingForPayment,
        .paymentProcessing,
        .verifying,
        .paid,
        .sending,
    ]

    init(ownerAddress: String, currentToken: TokenItem, feeTokenItem: TokenItem) {
        self.ownerAddress = ownerAddress
        self.currentToken = currentToken
        self.feeTokenItem = feeTokenItem
    }

    func merge(
        bsdkTransactions: [TransactionRecord],
        exchangeTransactions: [ExchangeTransaction],
        onrampTransactions: [OnrampTransaction]
    ) -> [TransactionRecord] {
        var bsdkTransactionsGroupedByHash: [String?: [TransactionRecord]] = bsdkTransactions.grouped(by: \.hash)
        var output: [TransactionRecord] = []

        for exchangeTransaction in exchangeTransactions {
            // Step 1: Deterministic mapping
            if let bsdkTransactions = bsdkTransactionsGroupedByHash.removeValue(forKey: exchangeTransaction.payIn.hash)
                ?? bsdkTransactionsGroupedByHash.removeValue(forKey: exchangeTransaction.payOut.hash) {
                let info = ExchangeTransactionInfo(
                    transaction: exchangeTransaction,
                    provider: nil // [REDACTED_TODO_COMMENT]
                )
                output.append(contentsOf: bsdkTransactions.map { $0.withExtraInfo(.exchange(info)) })
                continue
            }

            // Step 2: Heuristic mapping
            // [REDACTED_TODO_COMMENT]

            // Step 3: Add synthetic transaction if needed
            if shouldAddSyntheticTransaction(from: exchangeTransaction) {
                output.append(makeSyntheticTransaction(from: exchangeTransaction))
            }
        }

        for onrampTransaction in onrampTransactions {
            // Step 1: Deterministic mapping
            if let bsdkTransactions = bsdkTransactionsGroupedByHash.removeValue(forKey: onrampTransaction.payOut.hash) {
                let info = OnrampTransactionInfo(
                    onrampTransaction: onrampTransaction,
                    provider: nil, // [REDACTED_TODO_COMMENT]
                    fiatCurrency: nil // [REDACTED_TODO_COMMENT]
                )
                output.append(contentsOf: bsdkTransactions.map { $0.withExtraInfo(.onramp(info)) })
                continue
            }

            // Step 2: Heuristic mapping
            // [REDACTED_TODO_COMMENT]

            // Step 3: Add synthetic transaction if needed
            if shouldAddSyntheticTransaction(from: onrampTransaction) {
                output.append(makeSyntheticTransaction(from: onrampTransaction))
            }
        }

        // Adding remaining BSDK transactions that were not enriched with exchange or onramp info
        for bsdkTransactions in bsdkTransactionsGroupedByHash {
            output.append(contentsOf: bsdkTransactions.value)
        }

        // [REDACTED_TODO_COMMENT]
        return output
    }

    private func shouldAddSyntheticTransaction(from exchangeTransaction: ExchangeTransaction) -> Bool {
        Self.activeExchangeTransactionStatuses.contains(exchangeTransaction.status)
    }

    private func shouldAddSyntheticTransaction(from onrampTransaction: OnrampTransaction) -> Bool {
        Self.activeOnrampTransactionStatuses.contains(onrampTransaction.status)
    }

    private func makeSyntheticTransaction(from exchangeTransaction: ExchangeTransaction) -> TransactionRecord {
        let info = ExchangeTransactionInfo(
            transaction: exchangeTransaction,
            provider: nil // [REDACTED_TODO_COMMENT]
        )
        let outgoing = isOutgoing(exchangeTransaction)
        let source: TransactionRecord.SourceType
        let destination: TransactionRecord.DestinationType
        let hash: String

        if outgoing {
            // Pay-in leg: the wallet sends the `from` asset to the provider deposit address.
            let amount = exchangeTransaction.from.actualAmount ?? exchangeTransaction.from.amount
            source = .single(.init(address: exchangeTransaction.fromAddress ?? .unknown, amount: amount))
            destination = .single(.init(address: .user(exchangeTransaction.payIn.address), amount: amount))
            hash = exchangeTransaction.payIn.hash ?? exchangeTransaction.txId // [REDACTED_TODO_COMMENT]
        } else {
            // Pay-out leg: the wallet receives the `to` asset at its payout address.
            let amount = exchangeTransaction.to.actualAmount ?? exchangeTransaction.to.amount
            source = .single(.init(address: .unknown, amount: amount)) // [REDACTED_TODO_COMMENT]
            destination = .single(.init(address: .user(exchangeTransaction.payOut.address), amount: amount))
            hash = exchangeTransaction.payOut.hash ?? exchangeTransaction.txId // [REDACTED_TODO_COMMENT]
        }

        return TransactionRecord(
            hash: hash,
            index: 0, // A single transaction record, therefore index is always 0
            source: source,
            destination: destination,
            fee: feeTokenItem.zeroFee, // Unknown at this point
            status: syntheticTransactionStatus(from: exchangeTransaction.status),
            isOutgoing: outgoing,
            type: .contractMethodName(name: Constants.swapMethodName),
            date: exchangeTransaction.createdAt,
            tokenTransfers: [], // No inner token transfers for exchange transactions because no such information is provided by the API
            extraInfo: TransactionRecord.TransactionRecordExtraInfo.exchange(info)
        )
    }

    private func makeSyntheticTransaction(from onrampTransaction: OnrampTransaction) -> TransactionRecord {
        // Onramp only has a pay-out leg (fiat -> crypto), so the wallet always receives.
        let amount = onrampTransaction.to.actualAmount ?? onrampTransaction.to.amount ?? 0
        let info = OnrampTransactionInfo(
            onrampTransaction: onrampTransaction,
            provider: nil, // [REDACTED_TODO_COMMENT]
            fiatCurrency: nil // [REDACTED_TODO_COMMENT]
        )

        return TransactionRecord(
            hash: onrampTransaction.payOut.hash ?? onrampTransaction.txId, // [REDACTED_TODO_COMMENT]
            index: 0, // A single transaction record, therefore index is always 0
            source: .single(.init(address: .unknown, amount: amount)), // [REDACTED_TODO_COMMENT]
            destination: .single(.init(address: .user(onrampTransaction.payOut.address), amount: amount)),
            fee: feeTokenItem.zeroFee, // Unknown at this point
            status: syntheticTransactionStatus(from: onrampTransaction.status),
            isOutgoing: false, // Onramp transactions are always incoming by definition (fiat -> crypto)
            type: .contractMethodName(name: Constants.onrampMethodName),
            date: onrampTransaction.createdAt,
            tokenTransfers: [], // No inner token transfers for onramp transactions by definition
            extraInfo: TransactionRecord.TransactionRecordExtraInfo.onramp(info)
        )
    }

    private func isOutgoing(_ exchangeTransaction: ExchangeTransaction) -> Bool {
        // Fast path: using the owner address to determine the direction
        let isOnSendLeg = exchangeTransaction.fromAddress.map { ownerAddress.caseInsensitiveEquals(to: $0) } ?? false
        let isOnReceiveLeg = ownerAddress.caseInsensitiveEquals(to: exchangeTransaction.payOut.address)

        if isOnSendLeg != isOnReceiveLeg {
            return isOnSendLeg
        }

        // Slow path: the address is ambiguous (owner on both or neither leg, e.g. a swap sent to self),
        // using current token to determine the direction
        return currentToken.expressCurrency.asCurrency == exchangeTransaction.from.currency
    }

    private func syntheticTransactionStatus(from status: ExpressTransactionStatus) -> TransactionRecord.TransactionStatus {
        switch status {
        case .finished,
             .refunded:
            return .confirmed
        case .failed,
             .txFailed:
            return .failed
        case .unknown,
             .preview,
             .created,
             .exchangeTxSent,
             .waiting,
             .waitingTxHash,
             .expired,
             .confirming,
             .exchanging,
             .sending,
             .verifying,
             .paused:
            return .unconfirmed
        }
    }

    private func syntheticTransactionStatus(from status: OnrampTransactionStatus) -> TransactionRecord.TransactionStatus {
        switch status {
        case .finished,
             .refunded:
            return .confirmed
        case .failed:
            return .failed
        case .unknown,
             .created,
             .expired,
             .waitingForPayment,
             .paymentProcessing,
             .verifying,
             .paid,
             .sending,
             .refunding,
             .paused:
            return .unconfirmed
        }
    }
}

// MARK: - Constants

private extension _TransactionHistoryDataMerger {
    enum Constants {
        static let swapMethodName = "swap"
        static let onrampMethodName = "onramp"
    }
}
